// Synthesizes to 99 slices at 147 MHz in XC3Sxxx-4 with XST-10.1i
`timescale 1ns / 1ns
`include "freq.vh"

// smoothly interpolate y, such that the output takes CIC_PERIOD cycles to make
// the change given at the strobe pulse.
//
// take sixteen cycles to compute (approximately) y*CIC_MULT, then
// call interpol
//
// Typical values: CIC_PERIOD = 112, CIC_MULT=128/112=1.001001001001
// CIC_PERIOD=350, CIC_MULT=47934
//
module interpon_hg(
	input clk,  // timespec 6.8 ns
	input [16:0] y_in,
	input strobe,
	output signed [17:0] y_out,
	output timing_error,
	output data_error
);

reg strobe1=0;
reg [16:0] y_hold=0, y_prev=0;
reg signed [16:0] dy=0;
reg signed [17:0] accum=0;
reg a0=0, a1=0, a2=0;
reg [3:0] mcount=0;
reg mdone0=0, mdone1=0;
`define MSHIFT 1
//`define CIC_MULT 16'b1001001001001001   //   8/7   16'd37449
//`define CIC_MULT 16'b1010001111010111   //  64/50  16'd41943
//`define CIC_MULT 16'b1010001111010111   //  512/350  16'd47934
reg [15:0] k=47934;//  by hg for lcls test `CIC_MULT;
reg timing_error_r;
always @(posedge clk) begin
	if (strobe) y_hold <= y_in;
	if (strobe) y_prev <= y_hold;
	if (strobe) dy <= y_in - y_hold;
	strobe1 <= strobe;
	if (strobe1 | (|mcount)) mcount <= mcount+1;
	mdone0 <= &mcount;
	mdone1 <= mdone0;
	a0 <= strobe1 | (|mcount);  // latch enable
	a1 <= k[mcount];    // mask for dy>>1
	a2 <= (|mcount);    // mask for accum>>`MSHIFT
	if (a0) accum <= ({dy[16],dy[16:0]} & {18{a1}}) +
	                 ({{`MSHIFT{accum[17]}},accum[17:`MSHIFT]} & {18{a2}});
	if (strobe) timing_error_r <= a1;
end

wire t_error1;
//interpol #(.period(`CIC_PERIOD), .cntw(`CIC_CNTW))
interpol #(.period(350), .cntw(9))
	i(.clk(clk), .dy(dy), .dy7(accum), .strobe(mdone1),
	.y(y_out), .timing_error(t_error1));

// It's easy to check for faults, harder to fix them.
reg check1=0, data_error_r=0;
always @(posedge clk) begin
	check1 <= mdone1;
	if (check1) data_error_r <= y_out[16:0] != y_prev;
end

assign timing_error = timing_error_r | t_error1;
assign data_error = data_error_r;

endmodule
