// Synthesizes to 17 slices at 155 MHz in XC3Sxxx-4 using XST-10.1i

// Transform a raw phase difference (-pi to pi) into a control signal
// for a PLL.  Uses internal state to generate the right full-scale
// DC signal when the frequencies are mismatched.  In the final,
// locked-at-zero-phase state, the output equals the input.

`timescale 1ns / 1ns
module pdetect(clk, ang_in, strobe_in, ang_out, strobe_out);
parameter w=17;
	input clk;
	input [w-1:0] ang_in;
	input strobe_in;
	output reg [w-1:0] ang_out;
	output reg strobe_out;

// coding is important, see usage of next bits below
reg [1:0] state=0;
`define S_LINEAR 0
`define S_CLIP_P 2
`define S_CLIP_N 3

initial ang_out=0;
initial strobe_out=0;

reg [1:0] prev_quad=0;
wire [1:0] quad = ang_in[w-1:w-2];
wire trans_pn = (prev_quad==2'b01) & (quad==2'b10);
wire trans_np = (prev_quad==2'b10) & (quad==2'b01);

reg [1:0] next=0;
always @(*) begin
	next=state;
	if (trans_pn & (state==`S_LINEAR)) next=`S_CLIP_P;
	if (trans_np & (state==`S_LINEAR)) next=`S_CLIP_N;
	if (trans_pn & (state==`S_CLIP_N)) next=`S_LINEAR;
	if (trans_np & (state==`S_CLIP_P)) next=`S_LINEAR;
end

wire [w-1:0] clipv = {next[0],{w-1{~next[0]}}};
always @(posedge clk) if (strobe_in) begin
	prev_quad <= quad;
	state <= next;
	ang_out <= next[1] ? clipv : ang_in;
end
always @(posedge clk) strobe_out <= strobe_in;

endmodule
