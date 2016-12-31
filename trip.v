// Synthesizes to 69 slices at 125 MHz in XC3Sxxx-5 using XST-12.1
`timescale 1ns / 1ns

module trip(
	input clk,     // timespec 8.0 ns
	input signed [8:0] inval,
	input gate,    // high for first cycle of IQ pair
	input [11:0] trip_thresh,
	input reset,   // resets tripped state
	input clear,   // clears peak_val
	output reg tripped,
	output reg [11:0] peak_val
);

reg [7:0] inabs=0;
always @(posedge clk) begin
	inabs <= inval[8] ? ~inval[7:0] : inval[7:0];
end

wire [10:0] insquared;
square sq1(.v(inabs),.v2(insquared));

reg [10:0] last_sq=0, prev_sq=0;
reg [11:0] sum_sq=0, pipe_sum_sq=0;
reg trip=0;
reg gate_d1=0, gate_d2=0, gate_d3=0, gate_d4=0, gate_d5=0;
always @(posedge clk) begin
	last_sq <= insquared;
	prev_sq <= last_sq;
	sum_sq <= last_sq + prev_sq;  // all unsigned
	gate_d1 <= gate;
	gate_d2 <= gate_d1;
	gate_d3 <= gate_d2;
	gate_d4 <= gate_d3;
	gate_d5 <= gate_d4;

	trip <= sum_sq > trip_thresh;
	if (reset | gate_d5 & trip) tripped <= ~reset;

	// can't pipeline this step easily
	// my first simple attempt used a stale peak_val for comparison
	if (clear | gate_d4 & (sum_sq > peak_val)) peak_val <= clear ? 0 : sum_sq;
end

endmodule
