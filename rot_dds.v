// Synthesizes to ??? slices at ??? MHz in XC3Sxxx-4 using XST-??

`timescale 1ns / 1ns

module rot_dds(
	input clk,  // timespec 9.0 ns
	input reset,  // active high, synchronous with clk
	output signed [17:0] sina,
	output signed [17:0] cosa,
	input [19:0] phase_step_h,
	input [11:0] phase_step_l,
	input [11:0] modulo
);

// 2^17/1.64676 = 79594, use a smaller value to keep CORDIC round-off
// from overflowing the output
parameter lo_amp = 18'd79590;
// Sometimes we cheat and use slightly smaller values than above,
// to make other computations fit better.

// 12-bit modulo supports largest known periodicity in a
// suggested LLRF system, 1427 for JLab.  For more normal
// periodicities, use a multiple to get finer granularity.
// Note that the downloaded modulo control is the 2's complement
// of the mathematical modulus.
// e.g., SSRF IF/F_s ratio 8/11, use
//     modulo = 4096 - 372*11 = 4
//     phase_step_h = 2^20*8/11 = 762600
//     phase_step_l = (2^20*8%11)*372 = 2976
// e.g., Argonne RIA test IF/F_s ratio 9/13, use
//     modulo = 4096 - 315*13 = 1
//     phase_step_h = 2^20*9/13 = 725937
//     phase_step_l = (2^20*9%13)*315 = 945
// See rot_dds_config

// Note that phase_step_h and phase_step_l combined fit in a 32-bit word.
// This is intentional, to allow atomic updates of the two controls
// in 32-bit systems.  Indeed, when modulo==0, those 32 bits can be considered
// a simple binary DDS control.

reg carry=0, reset1=0;
reg [19:0] phase_h=0, phase_step_hp=0;
reg [11:0] phase_l=0;
always @(posedge clk) begin
	{carry, phase_l} <= reset ? 13'b0 : ((carry ? modulo : 12'b0) + phase_l + phase_step_l);
	phase_step_hp <= phase_step_h;
	reset1 <= reset;
	phase_h <= reset1 ? 20'b0 : (phase_h + phase_step_hp + carry);
end

cordicg #(.width(18), .def_op(0)) trig(.clk(clk), .opin(2'b00),
	.xin(lo_amp), .yin(18'd0), .phasein(phase_h[19:1]),
// 2^17/1.64676 = 79594, use a smaller value to keep CORDIC round-off
// from overflowing the output
	.xout(cosa), .yout(sina));

endmodule
