// Synthesizes to 19 slices at 135 MHz in XC3Sxxx-4 using XST-9.2.04i
`timescale 1ns / 1ns

// traditional multiplier
//
// X has the multiplier X for one cycle when load is high,
// then the multiplicand Y for the w following cycles.
// After those w+1 cycles total, R is valid and strobe goes high.
// The prestrobe output leads strobe by one cycle.
module mult_trad(clk,X,Y,load,R,strobe,prestrobe);

	parameter w=16;
	input clk;  // timespec 7.4 ns
	input [w-1:0] X;
	input signed [w-2:0] Y;
	input load;
	output signed [2*w-1:0] R;
	output strobe;
	output prestrobe;

reg signed [w-1:0] A=0;
reg [w-1:0] B=0;
reg [w+1:0] chain=0;
wire gate=B[0]&~load;
always @(posedge clk) begin
	// note sign extension in shift
	A <= ({w{~load}} & {A[w-1],A[w-1:1]}) + ({w{gate}} & {Y[w-2],Y});
	B <= ({w{~load}} & {A[  0],B[w-1:1]}) + ({w{load}} & X);
	chain <= {chain[w:0], load};
end

assign strobe=chain[w+1];
assign prestrobe=chain[w];
assign R={A,B};

endmodule
