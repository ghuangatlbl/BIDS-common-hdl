`timescale 1ns / 1ns

module source(
	input clk,
	input signed [15:0] sin,
	input signed [15:0] cos,
	output signed [15:0] d_out,
	input signed [15:0] ampi,
	input signed [15:0] ampq
);
// note that negative full-scale amplitude is considered invalid
// also plan that abs(ampi+ampq*i) < 1

// Universal definition; note: old and new are msb numbers, not bit widths.
`define SAT(x,old,new) ((~|x[old:new] | &x[old:new]) ? x[new:0] : {x[old],{new{~x[old]}}})

// So similar to phshift.v that maybe I don't need a testbench
reg signed [16:0] d3=0;
reg signed [31:0] p1=0, p2=0;  // product registers
wire signed [16:0] p1s = p1[30:14];
wire signed [16:0] p2s = p2[30:14];
wire signed [17:0] sum = p1s + p2s + 1;  // one lsb guard, with rounding
always @(posedge clk) begin
	p1 <= ampi * cos;
	p2 <= ampq * sin;
	d3 <= `SAT(sum, 17, 16);
end
assign d_out = d3[16:1];

endmodule
