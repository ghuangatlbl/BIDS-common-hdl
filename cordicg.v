// cordicg.v
// CORDIC processor
// Larry Doolittle, LBNL
// reference:
//   http://www.fpga-guru.com/cordic.htm
// Usage instructions: see README

`timescale 1ns / 1ns

module cordicg(clk, opin, xin, yin, phasein, xout, yout, phaseout);
	parameter width=19;
	parameter def_op=0;
	input clk;   // timespec 8.33 ns
	input [1:0] opin;  //  1 forces y to zero (rect to polar), 0 forces theta to zero (polar to rect), 3 for slave mode
	input [width-1:0] xin;
	input [width-1:0] yin;
	input [width:0] phasein;
	output [width-1:0] xout;
	output [width-1:0] yout;
	output [width:0] phaseout;

// input buffer stage (routing)
reg [1:0] opin0=def_op;
reg [width-1:0] xin0=0, yin0=0;
reg [width:0] phasein0=0;
always @(posedge clk) begin
	opin0    <= opin;
	xin0     <= xin;
	yin0     <= yin;
	phasein0 <= phasein;
end

// zero stage: doesn't quite fit the pattern
reg  [1:0] op0=def_op;
wire [width-1:0] xw0,  yw0  ; wire [width:0] zw0;
reg  [width-1:0] x0=0, y0=0 ; reg  [width:0] z0=0;
wire control0_l = opin0[0] ? xin0[width-1] : phasein0[width]^phasein0[width-1];
reg control0_h=0;
// No inversion of control0_h, unlike all the other stages!
// Rotation is either 0 or 180, which are their own inverses.
wire control0 = opin0[1] ? control0_h : control0_l;
addsubg #(width) ax0 ({width{1'b0}}, xin0, xw0, ~control0);
addsubg #(width) ay0 ({width{1'b0}}, yin0, yw0, ~control0);
assign zw0 = {phasein0[width]^control0,phasein0[width-1:0]};
always @(posedge clk) begin op0 <= opin0; x0 <= xw0; y0 <= yw0; z0 <= zw0; control0_h <= control0_l; end

// first stage: can't use cstageg because repeat operator of zero is illegal
reg  [1:0] op1=def_op;
wire [width-1:0] xw1,   yw1   ; wire [width:0] zw1;
reg  [width-1:0] xt1=0, yt1=0 ; reg  [width:0] zt1=0;
wire control1_l = op0[0] ? ~y0[width-1] : z0[width];
reg control1_h=0;
wire control1 = op0[1] ? ~control1_h : control1_l;
addsubg #(width) ax1 (x0, y0, xw1,  control1);
addsubg #(width) ay1 (y0, x0, yw1, ~control1);
addsubg #(width+1) az1 (z0, {3'b001,{(width-2){1'b0}}}, zw1,  control1);
always @(posedge clk) begin op1 <= op0; xt1 <= xw1; yt1 <= yw1; zt1 <= zw1; control1_h <= control1_l; end

// meat
`define CORDIC_COMPUTE
`include "cordicg.vh"
`undef CORDIC_COMPUTE

endmodule
