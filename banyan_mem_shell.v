// Instantiates banyan_mem at the interior of an FPGA fabric,
// with not too many I/O pins, and no way for the synthesizer
// to optimize anything away.  The point is to evaluate banyan_mem
// for synthesizability, size, and speed.  It would be useless
// to actually run this on hardware.
module banyan_mem_shell(
	input clk,  // timespec 6.1 ns
	input [14:0] lb_addr,
	input lb_write,
	input [31:0] lb_data,
	output [15:0] result,
	output [15:0] status
);

// 8 blocks of RAM, each 4K x 16
parameter aw=12;
parameter dw=16;

// IOB latches on inputs
reg [14:0] addr=0;
reg write=0;
reg [31:0] data=0;
always @(posedge clk) begin
	addr <= lb_addr;
	write <= lb_write;
	data <= lb_data;
end

// Semi-realistic local bus control
reg [7:0] banyan_mask=0;
reg rnd_run=0;
reg trig=0;
wire init_1 = write & (addr==1);
wire init_2 = write & (addr==2);
wire init_3 = write & (addr==3);
wire init_4 = write & (addr==4);
always @(posedge clk) if (write & (addr==5)) banyan_mask <= data;
always @(posedge clk) if (write & (addr==7)) rnd_run <= data;
always @(posedge clk) trig <= write & (addr==0);

// 128 bits of pseudo-randomness
wire [31:0] random1, random2, random3, random4;
tt800 r1(.clk(clk), .en(rnd_run|init_1), .init(init_1), .initv(data), .y(random1));
tt800 r2(.clk(clk), .en(rnd_run|init_2), .init(init_2), .initv(data), .y(random2));
tt800 r3(.clk(clk), .en(rnd_run|init_3), .init(init_3), .initv(data), .y(random3));
tt800 r4(.clk(clk), .en(rnd_run|init_4), .init(init_4), .initv(data), .y(random4));
wire [127:0] fake_adc = {random1, random2, random3, random4};

// Simple one-shot fill
reg run=0;
wire rollover, full;
always @(posedge clk) if (trig | rollover) run <= trig;
wire reset = trig;

// DUT instantiation
wire [aw+3-1:0] pointer;
wire [aw+3-1:0] ro_addr = addr;
wire [dw-1:0] ro_data;
banyan_mem #(.aw(aw), .dw(dw)) banyan_mem(.clk(clk),
	.adc_data(fake_adc), .banyan_mask(banyan_mask),
	.reset(reset), .run(run),
	.pointer(pointer), .rollover(rollover), .full(full),
	.ro_clk(clk), .ro_addr(ro_addr), .ro_data(ro_data)
);

// IOB latch on output
reg [dw-1:0] result_r=0;
always @(posedge clk) result_r <= ro_data;
assign result = result_r;
reg [15:0] status=0;
always @(posedge clk) status <= {full, run, pointer};

endmodule
