`timescale 1ns / 1ns

// programmable phase shifter, suited for carriers near f_sample/8,
//  e.g., f_sample/7 used in APEX
module phshift(
	input clk,  // timespec 8.0 ns
	input signed [15:0] d_in,
	output signed [15:0] d_out,
	input signed [15:0] gain1,
	input signed [15:0] gain2
);

// Universal definition; note: old and new are msb numbers, not bit widths.
`define SAT(x,old,new) ((~|x[old:new] | &x[old:new]) ? x : {x[old],{new{~x[old]}}})

// z-transform filter gain
//  gain1 + gain2*z^{-2}
reg signed [15:0] d1=0, d2=0;  // input z^(-1) registers
reg signed [31:0] p1=0, p2=0;  // product registers
wire signed [16:0] p1s = p1[30:14];
wire signed [16:0] p2s = p2[30:14];
wire signed [17:0] sum = p1s + p2s + 1;  // one lsb guard, with rounding
reg signed [16:0] d3=0;  // sum register

always @(posedge clk) begin
	d1 <= d_in;
	d2 <= d1;
	p1 <= gain1 * d_in;
	p2 <= gain2 * d2;
	d3 <= `SAT(sum, 17, 16);
end
assign d_out = d3[16:1];

endmodule
