// Synthesizes to 346 slices at 130 MHz in XC3Sxxx-4 using XST-10.1i
// (with notch filter selected)

`timescale 1ns / 1ns

// Actual scaling (given the default pi_shift and mult_shift parameters)
// as determined by simulation:
//   when ki == 16000
//     a static value of 14000 on phase input becomes a slope of 26.7 per cycle
//     consistent with an integral gain of ki*2^{-23) /cycle
//   when kp == 8000
//     a step change of 14000 in phase input becomes a step of 427.75
//     consistent with a proportional gain of kp*2^{-18}
// (this does not match Gang's piloop.v)
module piloop2(clk,sigin,refin,kp,ki,static_set,strobe_in,
	reverse,notch_enable,lo128,ctrlout,diffout,strobe_out);
parameter win=18;  // width for sigin, refin
parameter w=16;    // width for kp, ki, static_set, ctrlout
	input clk;  // timespec 7.69 ns
	input signed [win-1:0] sigin;
	input signed [win-1:0] refin;
	input [w-1:0] kp;
	input [w-1:0] ki;
	input signed [w-1:0] static_set;
	input strobe_in;
	input reverse;
	input notch_enable;
	input [6:0] lo128;
	output reg signed [w-1:0] ctrlout;
	output reg signed [win-1:0] diffout;
	output reg strobe_out;  // approx. 4*w+3 cycles after strobe_in

// For a given set of control words
parameter mult_shift=6; // actual analog Kp and Ki scaled by 2^{-mult_shift}
parameter pi_shift=5;   // actual analog Ki scaled by 2^{pi_shift}
initial strobe_out=0;
initial ctrlout=0;

// Stage 1: difference between measured and reference angles (-pi to pi)
reg strobe_1=0;
wire signed [win-1:0] diff0=sigin-refin;
reg signed [win-1:0] diff=0;
always @ (posedge clk) begin
	if (strobe_in) diff <= reverse ? (-diff0) : diff0;
	strobe_1 <= strobe_in;
end

// Stage 2: turn raw angle difference to a stateful phase detector output
wire pd_done;
wire signed [win-1:0] pdiff;
pdetect #(.w(win)) pd(.clk(clk), .ang_in(diff), .strobe_in(strobe_1),
	.ang_out(pdiff), .strobe_out(pd_done));
always @(posedge clk) diffout <= pdiff;  // slow, async (acoustic) monitor only

// Universal definition; note: old and new are msb numbers, not bit widths.
`define SAT(x,old,new) ((~|x[old:new] | &x[old:new]) ? x : {x[old],{new{~x[old]}}})

// Waste a cycle -- this could be done in pdetect in zero time and
// almost no extra gates.
reg signed [w-1:0] lmt_diff=0;
reg pdl_done=0;
always @(posedge clk) begin
	lmt_diff <= `SAT(pdiff,win-1,w-1);
	pdl_done <= pd_done;
end

// Dual narrow-band notch filter is both compile-time and run-time optional.
// "Any feature that cannot be disabled should be considered a bug."
//  -- me, http://lists.busybox.net/pipermail/busybox/2004-December/047438.html

wire signed [w-1:0] notch_out;
wire notch_done;
//`define USE_TWOFREQ
`ifdef USE_TWOFREQ
twofreq notch(.clk(clk), .enable(notch_enable),
	.v0(lmt_diff), .isync(pd_done), .p(lo128),
	.v1(notch_out), .osync(notch_done));
`else
assign notch_out = lmt_diff;
assign notch_done = pdl_done;
`endif

// Control signals from state machine (below)
wire x_sel, mult_str, integ_set, out_set;

// Value held between cycles in integrator
reg signed [2*w+1:0] integ_state=0;

// Main computational path: multiply pdiff by a constant, ...
wire [pi_shift-1:0] pi_pad = {pi_shift{1'b0}};
wire [w-1+pi_shift:0] mult_inx = x_sel ? {kp,pi_pad} : {pi_pad,ki} ;
wire signed [2*w+2*pi_shift+1:0] mult_result, mult_shifted;
wire mult_done;
mult_trad #(w+pi_shift+1) mult_p(.clk(clk), .X({1'b0,mult_inx}),
	.Y({{pi_shift{notch_out[w-1]}},notch_out}),
	.load(mult_str), .R(mult_result), .strobe(mult_done));
assign mult_shifted = {{mult_shift{mult_result[2*w+2*pi_shift+1]}},mult_result[2*w+2*pi_shift+1:mult_shift]};

// .. and saturated add to integrator state.
wire signed [2*w+1:0] add_result;
wire signed [2*w+2*pi_shift+1:0] integ_state_ext = {{2*pi_shift{integ_state[2*w+1]}},integ_state};

reg signed [2*w+2*pi_shift+2:0] add_result1 = 0;
reg signed [2*w+1:0] add_result2 = 0;
always @(posedge clk) begin
	add_result1 <= integ_state_ext + mult_shifted;
	add_result2 <= `SAT(add_result1, 2*w+2*pi_shift+2, 2*w+1);
end
assign add_result = add_result2; // XXX review consequences of new pipeline stage
//sat_add #(.isize(2*w+2*pi_shift+2), .osize(2*w+2)) a1(.clk(clk), .a(integ_state_ext),
//.b(mult_result), .sum(add_result));

// Two ways to use the result
// Set integrator to static value when kp and ki are zero
reg l_static=0;
always @(posedge clk) begin
	l_static <= (kp==0) & (ki==0);
	if (integ_set) integ_state <= l_static ? {static_set,{w+2{1'b0}}} : add_result;
	if (out_set) ctrlout <= add_result[2*w+1:w+2];
end

// State machine
reg s_idle=1, s_mulp=0, s_muli=0;
reg add_done=0;
always @(posedge clk) begin
	if (s_idle & notch_done ) begin s_idle <= 0; s_mulp <= 1; end
	if (s_mulp & add_done) begin s_mulp <= 0; s_muli <= 1; end
	if (s_muli & add_done) begin s_muli <= 0; s_idle <= 1; end
	add_done <= mult_done;
	strobe_out <= out_set;
end

// State machine decode
assign mult_str = s_idle & notch_done | s_mulp & mult_done;
assign x_sel = s_idle;
assign out_set = s_mulp & add_done;
assign integ_set = s_muli & add_done;

endmodule
