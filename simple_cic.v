`timescale 1ns / 1ns

module simple_cic(clk, reset, g_in, g_out, d_in, d_out);
	parameter in_width=16;
	parameter out_width=18;
	parameter cic_n=4;
	input clk;
	input reset;
	input g_in;
	output g_out;

	input signed [in_width-1:0] d_in;
	output signed [out_width-1:0] d_out;

reg [out_width+1-in_width:0] count=0;
reg [out_width-1:0] int1=0, prev_int1=0, diff1=0;
reg g_1=0;
wire last_count = count==cic_n-1;
always @(posedge clk) begin
	if (g_in) begin
		int1 <= int1 + d_in;
		count <= last_count ? 0 : count+1;
	end
	if (reset) count <= 0;
	g_1 <= g_in & last_count;
	if (g_1) begin
		prev_int1 <= int1;
		diff1 <= int1 - prev_int1;
	end
end
assign g_out=g_1;
assign d_out=diff1;
endmodule
