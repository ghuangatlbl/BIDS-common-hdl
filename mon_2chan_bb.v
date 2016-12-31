`timescale 1ns / 1ns

module mon_2chan_bb(clk,cos,sin,samp,s_in,s_out,g_in,g_out);
parameter dwi=16;  // data width
parameter rwi=28;  // result width
// Difference between above two widths should be N*log2 of the maximum number
// of samples per CIC sample, where N=2 is the order of the CIC filter.
	input clk;  // timespec 8.4 ns
	input signed [dwi-1:0] cos;
	input signed [dwi-1:0] sin;
	input samp;
	input signed [rwi-1:0] s_in;
	output signed [rwi-1:0] s_out;
	input g_in;
	output g_out;

parameter davr=3;

wire signed [rwi-1:0] s_reg1, s_reg2;
wire g_reg1, g_reg2;

// XXX data widths are minimally hacked to be compatible with mon_2chan
// but are probably not resource-optimized
wire signed [rwi-1:0] i1out;
double_inte #(.dwi(dwi+davr),.dwo(rwi))          i1(.clk(clk), .in({cos,{davr{1'b0}}}), .out(i1out));
serialize   #(.dwi(rwi))                         s1(.clk(clk), .samp(samp), .data_in(i1out),
	.stream_in(s_reg2), .stream_out(s_reg1), .gate_in(g_reg2), .gate_out(g_reg1));

wire signed [rwi-1:0] i2out;
double_inte #(.dwi(dwi+davr),.dwo(rwi))          i2(.clk(clk), .in({sin,{davr{1'b0}}}), .out(i2out));
serialize   #(.dwi(rwi))                         s2(.clk(clk), .samp(samp), .data_in(i2out),
	.stream_in(s_in), .stream_out(s_reg2), .gate_in(g_in), .gate_out(g_reg2));

assign s_out = s_reg1;
assign g_out = g_reg1;

endmodule
