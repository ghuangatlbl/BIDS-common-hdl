module circle_buf4_degrade(
    wclk, data_w, data_gate_in,
    trig_ext, trig_internal_ena, trigger_location, full_flag,
    rclk,stb_r, addr_r, data_r, data_gate_out, empty_flag,
    reset, stb_w, trig_out, buf_count, buf_stat, triggerable_flag,
    r_bank_available,r_addr,rewind
);
parameter aw=13;//for each half of the double-buffered memory
parameter dw=16;
parameter dma=0;//if 'dma=0' this module is the same as circle_buf3

//PORT DEFINITION BEGIN
//write side
input wclk;
input [dw-1:0] data_w;//data to be written
input data_gate_in;//data valid gate
input trig_ext;//external trigger in
input trig_internal_ena;//selection: 1: trig internal 0: external
input [aw-1:0] trigger_location;//locate the trig in the middle of waveform
output full_flag;//Buffer full flag
//readout side
input rclk;//read clk
input stb_r;//read enable
input [aw-1:0] addr_r;//read address
output [dw-1:0] data_r;//data output
output reg data_gate_out=0;//readable flag
output empty_flag;//Buffer empty_flag
//buffer reset
input reset;
input rewind;

//additional port
input stb_w;
output reg trig_out=0;
output reg [15:0] buf_count=0;
output [15:0] buf_stat;
output triggerable_flag;
output r_bank_available;
output reg  [aw-1:0] r_addr={aw{1'b0}};


//registers definition
reg w_bank=1'b0;
reg r_bank=1'b1;
reg w_bank_x=1'b0;
reg r_bank_x=1'b0;

always @(posedge wclk) begin
	r_bank_x<=r_bank;
end
always @(posedge rclk) begin
	w_bank_x<=w_bank;
end

reg [aw-1:0] w_addr={aw{1'b0}};
reg [aw-1:0] data_cnt={aw{1'b0}};

//reg [aw-1:0] addr_start0={aw{1'b0}};
//reg [aw-1:0] addr_start1={aw{1'b0}};
//wire [aw-1:0] addr_start_r=r_bank ? addr_start1 : addr_start0;
//wire [aw-1:0] addr_start_w=w_bank ? addr_start1 : addr_start0;

wire [aw-1:0] r_addr_buf=r_addr;
wire [aw-1:0] w_addr_buf=w_addr;

reg triggered=1'b0;

reg w_done=1'b0;
wire bank_same_wx=(~w_bank^r_bank_x);
wire w_last=(&w_addr);
wire w_done_pre=(&w_last)&triggered&stb_w;
wire w_swap=((~r_bank_x)^w_bank)&(w_done_pre&stb_w|w_done);
wire w_first=~(|w_addr);
wire w_enable=(~w_done)&stb_w&(triggered|trig_ena);
assign full_flag=w_done;

wire trig_ena;
// w_done is set when not finish reading
always @(posedge wclk) begin
	//w_done<=w_done ? w_last : (w_done_pre&(~w_swap));
	w_done<=w_done ? (w_first&(~w_swap)) : w_done_pre&(r_bank_x^w_bank);
end


reg r_done=1'b0;
wire bank_diff_rx=(w_bank_x^r_bank);
wire r_enable=(stb_r)&bank_diff_rx&(~rewind);
wire r_done_pre=(&r_addr);
wire r_swap=bank_diff_rx&(r_done_pre&stb_r);
assign empty_flag=~bank_diff_rx;
assign r_bank_available=bank_diff_rx;

always @(posedge rclk) begin
	//w_done<=w_done ? w_last : (w_done_pre&(~w_swap));
end

// change w_addr to right location
wire w_spin=(~trig_internal_ena)&trig_ena;
// write address counter
always @(posedge wclk /* or posedge reset */) begin
	if (reset) begin
		w_addr<={aw{1'b0}};
		data_cnt<={aw{1'b0}};
	end
	else if (w_enable|w_swap|w_spin) begin
		w_addr<=w_spin ? {{(aw-1){1'b0}},w_enable} : w_addr+{{(aw-1){1'b0}},1'b1^(w_first&w_swap)};
		data_cnt<=(w_swap) ? {aw{1'b0}} : (data_cnt+{{(aw-1){1'b0}},1'b1^(&data_cnt)});
	end

	if (reset)
		w_bank<=1'b0;
	else if (w_swap)
		w_bank<=~w_bank;
end
// read address counter
always @(posedge rclk /* or posedge reset */) begin
	if (reset)
		r_addr<={aw{1'b0}};
	else if (r_enable)
		r_addr<=r_addr+1'b1;
	else if (rewind)
		r_addr<=1'b0;
	if (reset)
		r_bank<=1'b1;
	else if (r_swap)
		r_bank<=~r_bank;
end
// trigger
// trig_ena
assign trig_ena=trig_internal_ena ? ~(w_done):trig_ext&(~triggered);
always @(posedge wclk /* or posedge reset */) begin
	if (reset) begin
		triggered<=trig_internal_ena;
		//addr_start0<={aw{1'b0}};
		//addr_start1<={aw{1'b0}};
	end
	else if (trig_internal_ena) begin
		triggered<=triggered ? (~w_done_pre|w_swap):(trig_ena);
		//addr_start0<={aw{1'b0}};
		//addr_start1<={aw{1'b0}};
	end
	else begin
		triggered<=triggered ? (~(w_swap)):(trig_ena);
		//addr_start0<=w_swap&(w_bank) ? {aw{1'b0}} : (~w_bank)&trig_ena ? w_addr : addr_start0;
		//addr_start1<=w_swap&(~w_bank) ? {aw{1'b0}} : (w_bank)&trig_ena ? w_addr : addr_start1;
	end
end

wire [dw-1:0] data_out;
reg [dw-1:0] data_out_r={dw{1'b0}};
always @(posedge rclk /* or posedge reset */) begin
	if (reset) begin
		data_gate_out<=1'b0;
		data_out_r<={aw{1'b0}};
	end else
	begin
		data_gate_out<=r_enable;
		data_out_r<=data_gate_out ? data_out : data_out_r;
	end
end
assign data_r=data_gate_out ? data_out : data_out_r;


dpram #(.aw(aw+1), .dw(dw)) mem(.clka(wclk), .clkb(rclk),
	.addra({w_bank,w_addr_buf}), .dina(data_w), .wena(w_enable),
	.addrb({r_bank,r_addr_buf}), .doutb(data_out)
);
endmodule
