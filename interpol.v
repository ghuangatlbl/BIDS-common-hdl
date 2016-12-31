`timescale 1ns / 1ns

// smoothly integrate dy, such that y takes period cycles to make
// the dy change given at the strobe pulse.
// One upper bit of y is added to support division-by-two in the phase sense,
// ignore that if you don't want it.
//
// phase 1 ( period - 2^(cntw-1) cycles): add dy7/2^cntw
// phase 2 (          2^(cntw-1) cycles): add remain/2^(cntw-1)
//
// example (default):
//  period=112
//  cntw=7
//  phase 1 lasts 48 cycles, step is dy7/128 ~ dy/112
//  phase 2 lasts 64 cycles, step is remain/64
//  dy7 is approximation to dy*(2^cntw/period)
//
module interpol(
	input clk,
	input signed [16:0] dy,
	input signed [17:0] dy7,   // valid same clk as dy
	input strobe,
	output [17:0] y,
	output timing_error
);
parameter cntw=7;
parameter period=112;

// control signal synthesis
reg [cntw-1:0] ccnt=0;
reg strobe1=0;
wire [cntw-1:0] cic_preset = period-1;
reg timing_error_r=0;
always @(posedge clk) begin
	strobe1 <= strobe;
	ccnt <= strobe ? cic_preset : (ccnt-(|ccnt));//1'b1);
	if (strobe) timing_error_r <= |ccnt;
end
wire phase1 = ccnt[cntw-1];

// data path
reg [17+cntw:0] yr=0;
reg signed [16+cntw:0] remain=0;
reg [16:0] dyr=0;
reg [17:0] dy7r=0;
wire [17:0] incr = phase1 ? dy7r : remain[16+cntw:cntw-1];
always @(posedge clk) begin
	if (strobe) dyr <= dy;
	if (strobe) dy7r <= dy7;
	if (phase1) remain <= (strobe1 ? {dyr,1'b0,{(cntw-1){1'b1}}} : remain) -
		{{(cntw-1){dy7r[17]}}, dy7r};
	yr <= {yr[17+cntw:cntw],{cntw{~strobe1}}&yr[cntw-1:0]} + {{cntw{incr[17]}},incr};
end

assign y = yr[17+cntw:cntw];
assign timing_error = timing_error_r;

endmodule
