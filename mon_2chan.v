`timescale 1ns / 1ns

module mon_2chan #(
	parameter dwi=16,  // data width
	parameter rwi=28,  // result width
	// Difference between above two widths should be N*log2 of the maximum number
	// of samples per CIC sample, where N=2 is the order of the CIC filter.
	parameter davr=3,  // how many guard bits to keep in output of multiplier
	parameter dwlo=18  // Local Oscillator data width
) (
	input clk,  // timespec 8.4 ns
	input signed [dwi-1:0] adcf,  // possibly muxed
	input signed [dwlo-1:0] mcos,
	input signed [dwlo-1:0] msin,
	input samp,
	input signed [rwi-1:0] s_in,
	output signed [rwi-1:0] s_out,
	input g_in,
	output g_out
);


wire signed [rwi-1:0] s_reg1, s_reg2;
wire g_reg1, g_reg2;

wire signed [dwi+davr-1:0] m1out;
wire signed [rwi-1:0] i1out;
mixer       #(.dwi(dwi),.davr(davr),.dwlo(dwlo)) m1(.clk(clk), .adcf(adcf), .mult(mcos), .mixout(m1out));
double_inte #(.dwi(dwi+davr),.dwo(rwi))          i1(.clk(clk), .in(m1out), .out(i1out));
serialize   #(.dwi(rwi))                         s1(.clk(clk), .samp(samp), .data_in(i1out),
	.stream_in(s_reg2), .stream_out(s_reg1), .gate_in(g_reg2), .gate_out(g_reg1));

wire signed [dwi+davr-1:0] m2out;
wire signed [rwi-1:0] i2out;
mixer       #(.dwi(dwi),.davr(davr),.dwlo(dwlo)) m2(.clk(clk), .adcf(adcf), .mult(msin), .mixout(m2out));
double_inte #(.dwi(dwi+davr),.dwo(rwi))          i2(.clk(clk), .in(m2out), .out(i2out));
serialize   #(.dwi(rwi))                         s2(.clk(clk), .samp(samp), .data_in(i2out),
	.stream_in(s_in), .stream_out(s_reg2), .gate_in(g_in), .gate_out(g_reg2));

assign s_out = s_reg1;
assign g_out = g_reg1;

endmodule
