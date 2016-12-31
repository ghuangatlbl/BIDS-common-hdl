`timescale 1ns / 1ns

// Cascaded Integrator Multiplexor
module cim_17(
	clk,
	adc01,cos01,sin01,
	adc02,cos02,sin02,
	adc03,cos03,sin03,
	adc04,cos04,sin04,
	adc05,cos05,sin05,
	adc06,cos06,sin06,
	adc07,cos07,sin07,
	adc08,cos08,sin08,
	adc09,cos09,sin09,
	adc10,cos10,sin10,
	adc11,cos11,sin11,
	adc12,cos12,sin12,
	adc13,cos13,sin13,
	adc14,cos14,sin14,
	adc15,cos15,sin15,
	adc16,cos16,sin16,
	adc17,cos17,sin17,
	sample,

	// unprocessed double-integrator output
	sr_out,
	sr_val
);

parameter dw=32;  // data width of mon_chan output
// should be CIC input data width (18), plus 2 * log2(max sample period)
// also should match width of sr_out port

input clk;
input signed [15:0] adc01,adc02,adc03,adc04,adc05,adc06,adc07,adc08,adc09,adc10,adc11,adc12,adc13,adc14,adc15,adc16,adc17;
input signed [17:0] cos01,cos02,cos03,cos04,cos05,cos06,cos07,cos08,cos09,cos10,cos11,cos12,cos13,cos14,cos15,cos16,cos17;
input signed [17:0] sin01,sin02,sin03,sin04,sin05,sin06,sin07,sin08,sin09,sin10,sin11,sin12,sin13,sin14,sin15,sin16,sin17;
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
wire signed [dw-1:0] s03;  wire g03;  mon_2chan #(.dwi(16), .rwi(dw)) mon01(.clk(clk), .adcf(adc01), .mcos(cos01), .msin(sin01), .samp(sample), .s_in(s03), .s_out(s01), .g_in(g03), .g_out(g01));
wire signed [dw-1:0] s05;  wire g05;  mon_2chan #(.dwi(16), .rwi(dw)) mon02(.clk(clk), .adcf(adc02), .mcos(cos02), .msin(sin02), .samp(sample), .s_in(s05), .s_out(s03), .g_in(g05), .g_out(g03));
wire signed [dw-1:0] s07;  wire g07;  mon_2chan #(.dwi(16), .rwi(dw)) mon03(.clk(clk), .adcf(adc03), .mcos(cos03), .msin(sin03), .samp(sample), .s_in(s07), .s_out(s05), .g_in(g07), .g_out(g05));
wire signed [dw-1:0] s09;  wire g09;  mon_2chan #(.dwi(16), .rwi(dw)) mon04(.clk(clk), .adcf(adc04), .mcos(cos04), .msin(sin04), .samp(sample), .s_in(s09), .s_out(s07), .g_in(g09), .g_out(g07));
wire signed [dw-1:0] s11;  wire g11;  mon_2chan #(.dwi(16), .rwi(dw)) mon05(.clk(clk), .adcf(adc05), .mcos(cos05), .msin(sin05), .samp(sample), .s_in(s11), .s_out(s09), .g_in(g11), .g_out(g09));
wire signed [dw-1:0] s13;  wire g13;  mon_2chan #(.dwi(16), .rwi(dw)) mon06(.clk(clk), .adcf(adc06), .mcos(cos06), .msin(sin06), .samp(sample), .s_in(s13), .s_out(s11), .g_in(g13), .g_out(g11));
wire signed [dw-1:0] s15;  wire g15;  mon_2chan #(.dwi(16), .rwi(dw)) mon07(.clk(clk), .adcf(adc07), .mcos(cos07), .msin(sin07), .samp(sample), .s_in(s15), .s_out(s13), .g_in(g15), .g_out(g13));
wire signed [dw-1:0] s17;  wire g17;  mon_2chan #(.dwi(16), .rwi(dw)) mon08(.clk(clk), .adcf(adc08), .mcos(cos08), .msin(sin08), .samp(sample), .s_in(s17), .s_out(s15), .g_in(g17), .g_out(g15));
wire signed [dw-1:0] s19;  wire g19;  mon_2chan #(.dwi(16), .rwi(dw)) mon09(.clk(clk), .adcf(adc09), .mcos(cos09), .msin(sin09), .samp(sample), .s_in(s19), .s_out(s17), .g_in(g19), .g_out(g17));
wire signed [dw-1:0] s21;  wire g21;  mon_2chan #(.dwi(16), .rwi(dw)) mon10(.clk(clk), .adcf(adc10), .mcos(cos10), .msin(sin10), .samp(sample), .s_in(s21), .s_out(s19), .g_in(g21), .g_out(g19));
wire signed [dw-1:0] s23;  wire g23;  mon_2chan #(.dwi(16), .rwi(dw)) mon11(.clk(clk), .adcf(adc11), .mcos(cos11), .msin(sin11), .samp(sample), .s_in(s23), .s_out(s21), .g_in(g23), .g_out(g21));
wire signed [dw-1:0] s25;  wire g25;  mon_2chan #(.dwi(16), .rwi(dw)) mon12(.clk(clk), .adcf(adc12), .mcos(cos12), .msin(sin12), .samp(sample), .s_in(s25), .s_out(s23), .g_in(g25), .g_out(g23));
wire signed [dw-1:0] s27;  wire g27;  mon_2chan #(.dwi(16), .rwi(dw)) mon13(.clk(clk), .adcf(adc13), .mcos(cos13), .msin(sin13), .samp(sample), .s_in(s27), .s_out(s25), .g_in(g27), .g_out(g25));
wire signed [dw-1:0] s29;  wire g29;  mon_2chan #(.dwi(16), .rwi(dw)) mon14(.clk(clk), .adcf(adc14), .mcos(cos14), .msin(sin14), .samp(sample), .s_in(s29), .s_out(s27), .g_in(g29), .g_out(g27));
wire signed [dw-1:0] s31;  wire g31;  mon_2chan #(.dwi(16), .rwi(dw)) mon15(.clk(clk), .adcf(adc15), .mcos(cos15), .msin(sin15), .samp(sample), .s_in(s31), .s_out(s29), .g_in(g31), .g_out(g29));
wire signed [dw-1:0] s33;  wire g33;  mon_2chan #(.dwi(16), .rwi(dw)) mon16(.clk(clk), .adcf(adc16), .mcos(cos16), .msin(sin16), .samp(sample), .s_in(s33), .s_out(s31), .g_in(g33), .g_out(g31));
wire signed [dw-1:0] s35;  wire g35;  mon_2chan #(.dwi(16), .rwi(dw)) mon17(.clk(clk), .adcf(adc17), .mcos(cos17), .msin(sin17), .samp(sample), .s_in(s35), .s_out(s33), .g_in(g35), .g_out(g33));

// terminate the chain
assign s35={dw{`FILL_BIT}};
assign g35 = 0;

// use the results of the chain
assign sr_out = s01;  // data
assign sr_val = g01;  // gate

endmodule
