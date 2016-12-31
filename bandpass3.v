`timescale 1ns / 1ns

module bandpass3(
	input clk,  // timespec 9.4 ns
	input signed [15:0] inp,
	input zerome,
	input oe,
	output reg signed [17:0] out,
	input signed [16:0] cm1,
	input signed [16:0] d
);

// cm1 and d are host-settable registers
// cm1 (read "c minus 1") and d are signed 17-bit
// integers, representing real numbers -0.5<=x<+0.5.
// That is, take the integer in the range -65536 to 65535
// and divide by 131072 to get the real number.

// z-transform filter gain
//  (1-z^{-1})/(a + b*z^{-1} + c*z^{-2} + d*z^{-3})
// hard-code a=1, b=-1, and use c=(1+cm1)
//
// With default cm1=0, d=0, turns into an infinite-Q filter centered
//  at acos(-b/2) = 2*pi/6 = 0.167*2*pi, close to APEX's 0.143*2*pi.
//  Use host-settable cm1 and d to adjust frequency and Q as desired,
//  see cubicr.m.
//
// Input differentiator expects dominant signal at 1/7*f_S.
// For an input A*sin(n*theta), max (1-z^{-1}) amplitude is
// A*2*sin(theta/2) = A*0.8678.  Accept the full range of input
// by including the next most significant bit; the next step will
// sign extend this a few bits anyway.
reg signed [15:0] ireg=0, ireg1=0;  // binary point to left of ireg[15]
reg signed [16:0] d1=0;             // binary point to left of d1[15]

// Q can be arbitrarily high, and this module will just clip.
reg signed [19:0] r0=0;
reg signed [18:0] r1=0;
reg signed [33:0] p1=0, p2=0;
reg signed [19:0] s0=0;
wire signed [19:0] p1s=p1[33:14];
wire signed [19:0] p2s=p2[33:14];

// Universal definition; note: old and new are msb numbers, not bit widths.
`define SAT(x,old,new) ((~|x[old:new] | &x[old:new]) ? x : {x[old],{new{~x[old]}}})

always @(posedge clk) begin
	ireg <= inp;
	ireg1 <= ireg;
	d1 <= ireg - ireg1;
	// conceptually: r2 <= r1 <= r0 <= d1 + r0 - (1+cm1)*r1 - d*r2;
	r1 <= {19{~zerome}} & `SAT(r0,19,18);  // avoid wind-up, implement clear
	p1 <= cm1*$signed(r0[19:3]);
	p2 <= d*$signed(r0[19:3]);
	s0 <= d1-p2s+1;
	r0 <= r0+s0-(p1s+r1);
	if (oe) out <= r1[18:1];
end
endmodule
