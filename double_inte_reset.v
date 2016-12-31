`timescale 1ns / 1ns

module double_inte_reset(clk,in,out,reset);
parameter dwi=16;  // data width in
parameter dwo=28;  // data width out n bits more the in, 2^n should be more than the cic factor^2 in sel case, 47^2=2209 adding 12 bit seems a little limited
	input clk;  // timespec 8.4 ns
	input reset;
	input signed [dwi-1:0] in;  // possibly muxed
	output signed [dwo-1:0] out;

reg signed [dwo-1:0] int1=0, int2=0;
reg ignore=0;
always @(posedge clk) begin
	if (reset) begin
		int1<=0;
		int2<=0;
	end
	else begin
		{int1,ignore} <= $signed({int1,1'b1}) +in;
		int2 <= int2 + int1;
	end
end
assign out = int2;

endmodule
