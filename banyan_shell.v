// Instantiates banyan at the interior of an FPGA fabric,
// with not too many I/O pins, and no way for the synthesizer
// to optimize anything away.  The point is to evaluate banyan
// for synthesizability, size, and speed.  It would be useless
// to actually run this on hardware.
module banyan_shell(
	input clk,  // timespec 6.1 ns
	input [2:0] lb_addr,
	input lb_write,
	input [31:0] lb_data,
	output [16:0] result
);

// IOB latches on inputs
reg [2:0] addr=0;
reg write=0;
reg [31:0] data=0;
always @(posedge clk) begin
	addr <= lb_addr;
	write <= lb_write;
	data <= lb_data;
end

reg run=0;
reg [2:0] out_sel=0;
reg [7:0] banyan_mask=0;
reg [2:0] time_state=0;
wire init_1 = write & (addr==1);
wire init_2 = write & (addr==2);
wire init_3 = write & (addr==3);
wire init_4 = write & (addr==4);
always @(posedge clk) if (write & (addr==5)) banyan_mask <= data;
always @(posedge clk) if (write & (addr==6)) out_sel <= data;
always @(posedge clk) if (write & (addr==7)) run <= data;
always @(posedge clk) begin
	if (write & (addr==7)) time_state <= 0;
	if (write & (addr==0)) time_state <= time_state+1;
end

// 128 bits of pseudo-randomness
wire [31:0] random1, random2, random3, random4;
tt800 r1(.clk(clk), .en(run|init_1), .init(init_1), .initv(data), .y(random1));
tt800 r2(.clk(clk), .en(run|init_2), .init(init_2), .initv(data), .y(random2));
tt800 r3(.clk(clk), .en(run|init_3), .init(init_3), .initv(data), .y(random3));
tt800 r4(.clk(clk), .en(run|init_4), .init(init_4), .initv(data), .y(random4));
wire [127:0] fake_adc = {random1, random2, random3, random4};

wire [7:0] mask_out;
wire [127:0] data_out;
`ifdef BASELINE
assign data_out = fake_adc;
assign mask_out = banyan_mask;
`else
banyan #(.dw(16), .np(8), .rl(3)) banyan(.clk(clk),
	.time_state(time_state),
	.mask_in(banyan_mask),
	.data_in(fake_adc),
	.mask_out(mask_out), .data_out(data_out));
`endif

reg [15:0] data_r=0;
reg flag_r=0;
always @(posedge clk) begin
	data_r <= data_out[out_sel*16+15 -: 16];
	flag_r <= mask_out[out_sel];
end

// IOB latch on output
reg [16:0] result_r=0;
always @(posedge clk) result_r <= {flag_r, data_r};
assign result = result_r;
endmodule
