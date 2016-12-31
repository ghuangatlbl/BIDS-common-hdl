`timescale 1ns / 100ps

module circle_buf2(wclk, stb_w, data_w, data_gate_in, trig_ext, trig_internal, trigger_location, rclk,stb_r, data_r,addr_r, trig_out,data_gate,reset,buf_count, buf_stat);

parameter aw=13;  // for each half of the double-buffered memory
parameter dw=16;
parameter dma=0;
// fsm states
localparam IDLE = 2'b00, READY = 2'b01, WORK = 2'b10, WAIT = 2'b11;

// write side
input wclk;
input stb_w;
input [dw-1:0] data_w; // data to be written
input data_gate_in; // data valid gate
input trig_ext;
input trig_internal;
input [aw-1:0] trigger_location;  // locate the trig in the middle of waveform
// readout side
input rclk;
input stb_r;
output reg trig_out;
output [dw-1:0] data_r;
output data_gate;
input reset;
input [aw-1:0] addr_r; // user input address to be read
output [15:0] buf_count;
output [15:0] buf_stat;

//wire [aw-1:0] addr_r_offset=r_addr_start+addr_r;

reg [aw-1:0] w_addr_start=0, w_addr=0, r_addr=0, r_addr_end=0, w_addr_cnt=0, r_addr_start=0;
reg w_bank=0;
reg [15:0] trig_missed=0;

wire [1:0] w_state, r_state;
wire [aw-1:0] w_addr_end= trig_internal ? w_addr_start -1'b1 : w_addr_start-1'b1 - trigger_location;

wire r_empty = (r_addr==r_addr_end) & stb_r;
wire w_full  = (w_addr==w_addr_end) & stb_w & w_state==WORK;

reg w_full_d=0, r_empty_d=0;
wire r_ready = r_state==IDLE | r_empty_d;
wire w_done  = w_full | w_state==WAIT;
wire trigger = trig_internal ? r_ready : trig_ext;
reg trigger_d=0, w_done_d=0, r_ready_d=0;
// make sure to write a full frame
wire w_data_full = &w_addr_cnt;

buf_fsm #(.IDLE(IDLE), .READY(READY), .WORK(WORK), .WAIT(WAIT)) w_fsm(
    .clk(wclk),
    .rst(reset),
    .t1(trigger & w_data_full),
    .t2(stb_w),
    .t3(w_full),
    .t4(r_ready),
    .go_work(1'b0),
    .loop_work(1'b0),
    .state(w_state)
);

buf_fsm #(.IDLE(IDLE), .READY(READY), .WORK(WORK), .WAIT(WAIT)) r_fsm(
    .clk(rclk),
    .rst(reset),
    .t1(w_done_d),
    .t2(stb_r),
    .t3(r_empty),
    .t4(1'b1),
    .go_work(1'b1),
    .loop_work(w_state==WAIT),
    .state(r_state)
);

reg [15:0] buf_count_r=0;
wire we = stb_w & data_gate_in & (w_state != WAIT);

// Write side
always @(posedge wclk) begin
    if (w_state == READY) w_addr_start <= w_addr;
    if (we) begin
        w_addr <= w_addr + 1'b1;
        //w_addr <= w_full ? w_addr : w_addr + 1'b1;
        w_addr_cnt <= w_state==READY ? 1 : (w_data_full ? w_addr_cnt : w_addr_cnt+1);
    end
    trigger_d <= trigger;
    if (trigger_d) trig_missed <= ( w_state != READY) ? (reset?0:trig_missed+1):trig_missed;
    if (w_full) buf_count_r <= buf_count_r + 1'b1;
    w_full_d <= w_full;
    w_done_d <= w_done;
end

// When to swap w_bank?
// 1. ( if write slow ) wclk: r_ready & w_full negedge
// 2. ( if read slow ) rclk: r_empty negedge & w_done
wire r_swap = r_empty_d & w_done_d;
wire w_swap = w_full_d & r_ready_d;
wire swap=w_swap || r_swap;
always @(posedge swap) begin
	w_bank = ~w_bank;
end

wire r_trig_out;
// Read side
always @(posedge rclk) begin
    r_addr_start <= w_addr_end + 1'b1;
    if (stb_r && r_state == WORK) r_addr <= dma? r_addr_start+addr_r : (r_empty? r_addr_start:r_addr + 1'b1);
    if (r_state == IDLE) begin
        r_addr <= w_addr_end + 1'b1;
        r_addr_end <= w_addr_end;
    end
    r_empty_d <= r_empty;
    r_ready_d <= r_ready;
    trig_out <= r_empty ? 0 : r_trig_out;
end

// data path is simply a dual-port RAM
dpram #(.aw(aw+1), .dw(dw)) dpram(.clka(wclk), .clkb(rclk),
	.addra({w_bank,w_addr}), .dina(data_w), .wena(we),
	.addrb({~w_bank,r_addr}), .doutb(data_r)
);

assign r_trig_out = (r_empty & w_done) | (w_full & r_ready);
assign buf_count = buf_count_r;
assign buf_stat = trig_missed;
assign data_gate = r_state==WORK;

endmodule
