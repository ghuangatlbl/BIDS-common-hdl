`timescale 1ns / 1ns

// Cascaded Integrator Multiplexor
module cim_16(
	clk,
	din01,cos01,sin01,
	din02,cos02,sin02,
	din03,cos03,sin03,
	din04,cos04,sin04,
	din05,cos05,sin05,
	din06,cos06,sin06,
	din07,cos07,sin07,
	din08,cos08,sin08,
	sample,

	// unprocessed double-integrator output
	sr_out,
	sr_val
);

parameter dw=32;  // data width of mon_chan output
// should be CIC input data width (18), plus 2 * log2(max sample period)
// also should match width of sr_out port

input clk;
input signed [15:0] din01,din02,din03,din04,din05,din06,din07,din08;
input signed [17:0] cos01,cos02,cos03,cos04,cos05,cos06,cos07,cos08;
input signed [17:0] sin01,sin02,sin03,sin04,sin05,sin06,sin07,sin08;
input sample;
output [dw-1:0] sr_out;
output sr_val;

`ifdef SIMULATE
`define FILL_BIT 1'bx
`else
`define FILL_BIT 1'b0
`endif

// Each mon_2chan instantiation includes (twice, one for cos, one for sin) the multiplier, double integrator, and sampling/shift-out register
// Snapshots double-integrator outputs at times flagged by "sample", then shifts the results out on the next twelve cycles.
wire signed [dw-1:0] s01;  wire g01;
wire signed [dw-1:0] s03;  wire g03;  mon_2chan #(.dwi(16), .rwi(dw),.davr(5)) mon01(.clk(clk), .adcf(din01), .mcos(cos01), .msin(sin01), .samp(sample), .s_in(s03), .s_out(s01), .g_in(g03), .g_out(g01));
wire signed [dw-1:0] s05;  wire g05;  mon_2chan #(.dwi(16), .rwi(dw),.davr(5)) mon02(.clk(clk), .adcf(din02), .mcos(cos02), .msin(sin02), .samp(sample), .s_in(s05), .s_out(s03), .g_in(g05), .g_out(g03));
wire signed [dw-1:0] s07;  wire g07;  mon_2chan #(.dwi(16), .rwi(dw),.davr(5)) mon03(.clk(clk), .adcf(din03), .mcos(cos03), .msin(sin03), .samp(sample), .s_in(s07), .s_out(s05), .g_in(g07), .g_out(g05));
wire signed [dw-1:0] s09;  wire g09;  mon_2chan #(.dwi(16), .rwi(dw),.davr(5)) mon04(.clk(clk), .adcf(din04), .mcos(cos04), .msin(sin04), .samp(sample), .s_in(s09), .s_out(s07), .g_in(g09), .g_out(g07));
wire signed [dw-1:0] s11;  wire g11;  mon_2chan #(.dwi(16), .rwi(dw),.davr(5)) mon05(.clk(clk), .adcf(din05), .mcos(cos05), .msin(sin05), .samp(sample), .s_in(s11), .s_out(s09), .g_in(g11), .g_out(g09));
wire signed [dw-1:0] s13;  wire g13;  mon_2chan #(.dwi(16), .rwi(dw),.davr(5)) mon06(.clk(clk), .adcf(din06), .mcos(cos06), .msin(sin06), .samp(sample), .s_in(s13), .s_out(s11), .g_in(g13), .g_out(g11));
wire signed [dw-1:0] s15;  wire g15;  mon_2chan #(.dwi(16), .rwi(dw),.davr(5)) mon07(.clk(clk), .adcf(din07), .mcos(cos07), .msin(sin07), .samp(sample), .s_in(s15), .s_out(s13), .g_in(g15), .g_out(g13));
wire signed [dw-1:0] s17;  wire g17;  mon_2chan #(.dwi(16), .rwi(dw),.davr(5)) mon08(.clk(clk), .adcf(din08), .mcos(cos08), .msin(sin08), .samp(sample), .s_in(s17), .s_out(s15), .g_in(g17), .g_out(g15));

// terminate the chain
assign s17={dw{`FILL_BIT}};
assign g17 = 0;

// use the results of the chain
assign sr_out = s01;  // data
assign sr_val = g01;  // gate

endmodule
