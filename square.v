// square.v
// trip and peak hold logic based on Pythagorean error
// $Id$
// Larry Doolittle, LBNL

// llc-suite Copyright (c) 2004, The Regents of the University of
// California, through Lawrence Berkeley National Laboratory (subject
// to receipt of any required approvals from the U.S. Dept. of Energy).
// All rights reserved.

// Your use of this software is pursuant to a "BSD-style" open
// source license agreement, the text of which is in license.txt
// (md5sum a1e0e81c78f6eba050b0e96996f49fd5) that should accompany
// this file.  If the license agreement is not there, or if you
// have questions about the license, please contact Berkeley Lab's
// Technology Transfer Department at TTD@lbl.gov referring to
// "llc-suite (LBNL Ref CR-1988)"

// Combinatorial approximate squaring: 8-bit input, 11-bit output
// (rounds the 5 lsbs).  Should synthesize to about 30 logic cells
// in any modern (4-input LUT) Xilinx or Altera FPGA.

`timescale 1ns / 1ns

module square(input [7:0] v, output [10:0] v2);

wire [3:0] v_hi = v[7:4];
wire [3:0] v_lo = v[3:0];
reg [7:0] v2b;
always @(v_hi) case(v_hi)
  4'd0:  v2b = 0;
  4'd1:  v2b = 1;
  4'd2:  v2b = 4;
  4'd3:  v2b = 9;
  4'd4:  v2b = 16;
  4'd5:  v2b = 25;
  4'd6:  v2b = 36;
  4'd7:  v2b = 49;
  4'd8:  v2b = 64;
  4'd9:  v2b = 81;
  4'd10: v2b = 100;
  4'd11: v2b = 121;
  4'd12: v2b = 144;
  4'd13: v2b = 169;
  4'd14: v2b = 196;
  4'd15: v2b = 225;
endcase

reg [2:0] v2f;
always @(v_lo) case(v_lo)
  4'd0:  v2f = 0;
  4'd1:  v2f = 0;
  4'd2:  v2f = 0;
  4'd3:  v2f = 0;
  4'd4:  v2f = 1;
  4'd5:  v2f = 1;
  4'd6:  v2f = 1;
  4'd7:  v2f = 2;
  4'd8:  v2f = 2;
  4'd9:  v2f = 3;
  4'd10: v2f = 3;
  4'd11: v2f = 4;
  4'd12: v2f = 5;
  4'd13: v2f = 5;
  4'd14: v2f = 6;
  4'd15: v2f = 7;
endcase

wire [3:0] p0 = { (v[4] ? v_lo : 4'b0)       };
wire [4:0] p1 = { (v[5] ? v_lo : 4'b0), 1'b0 };
wire [5:0] p2 = { (v[6] ? v_lo : 4'b0), 2'b0 };
wire [6:0] p3 = { (v[7] ? v_lo : 4'b0), 3'b0 };

assign v2 = {v2b,v2f} + p0 + p1 + p2 + p3;

endmodule
