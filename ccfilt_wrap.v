`timescale 1ns / 1ns

// Synthesis tester for ccfilt;
// there's no value in using this in a larger build.

// Using XST 12.1 targeting XC3S:
//  433 slices (658 LUTs) with full 4-bit shift
//  426 slices (636 LUTs) tying low shift bit to 0
//  437 slices (640 LUTs) tying low shift bit to 1 (matches old 3-bit case)
module ccfilt_wrap(
	input clk,   // timespec 9.2 ns
	// unprocessed double-integrator output
	input sr_out,
	input [35:0] sr_val,

	// semi-static configuration
	input [3:0] shift,  // controls scaling of result

	// filtered and scale result, ready for storage
	output reg [35:0] result,
	output reg strobe
);

reg [35:0] sr_out1;
reg sr_val1;
wire [19:0] result1;
wire strobe1;
reg [3:0] shift1;
always @(posedge clk) begin
	sr_out1 <= sr_out;
	sr_val1 <= sr_val;
	result <= result1;
	strobe <= strobe1;
	shift1 <= shift;
end

ccfilt #(.dw(36), .dsr_len(12)) ccfilt(.clk(clk),
	.sr_out(sr_out1), .sr_val(sr_val1),
	.shift({shift1[3:1],1'b0}),
	.result(result1), .strobe(strobe1)
);

endmodule
