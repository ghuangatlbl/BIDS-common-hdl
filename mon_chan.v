// XXX deprecated
`timescale 1ns / 1ns

module mon_chan(clk,adcf,mult,samp,s_in,s_out);
parameter dwi=16;  // data width
parameter rwi=28;  // result width
// Difference between above two widths should be N*log2 of the maximum number
// of samples per CIC sample, where N=2 is the order of the CIC filter.
	input clk;  // timespec 8.4 ns
	input signed [dwi-1:0] adcf;  // possibly muxed
	input signed [17:0] mult;
	input samp;
	input signed [rwi-1:0] s_in;
	output signed [rwi-1:0] s_out;

// adc value can be anything, including -F.S., but
// demand that multiplier is never -F.S., so there is
// an "extra" sign bit that can be ignored.
// Not a problem if we use the pi/4 value discussed in mon_1_tb

reg signed [17:0] mult_r=0;  // input register

reg signed [dwi+17:0] product1=0, product2=0;  // 16-bit x 18-bit = 34-bit
reg signed [rwi-1:0] int1=0, int2=0, s_r=0;
wire signed [18:0] product_out = product2[dwi+16:dwi-2]; // strip "extra" sign bit
reg ignore=0;
always @(posedge clk) begin
	mult_r <= mult;
	product1 <= adcf * mult_r;  // internal multiplier pipeline
	product2 <= product1;
	{int1,ignore} <= $signed({int1,1'b1}) + product_out;
	// int1 <= int1 + product_out;
	int2 <= int2 + int1;
	s_r <= samp ? int2 : s_in;
end
assign s_out = s_r;

endmodule
