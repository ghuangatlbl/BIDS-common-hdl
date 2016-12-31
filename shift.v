`timescale 1ns / 1ns

module shift(
	clk,
	data_in,
	strobe_in,
	shift,  // controls scaling of result
	data_out,
	strobe_out,
	ovf
);

parameter dw=32;  // data width of mon_chan output:
	// should be CIC input data width (18),
	// plus 2 * log2(max sample period)
parameter dsr_len = 12;  // expected length of strobe pattern
parameter use_hb = 1;  // compile-time conditional code

input clk;
input [dw-1:0] data_in;
input strobe_in;
input [3:0] shift;
output signed [19:0] data_out;
output strobe_out;
output ovf;

parameter dwmax = 36;
reg [20:0] shiftmem[15:0];
reg  ovfmem[15:0];
reg strobe_reg=0;
`define UNIFORM(x) ((~|(x)) | &(x))  // All 0's or all 1's
always @(posedge clk) begin
	if (strobe_in) begin
		shiftmem[0]<=data_in[20:0];ovfmem[0] <= ~`UNIFORM(data_in[dwmax:20]);
		shiftmem[1]<=data_in[21:1];ovfmem[1] <= ~`UNIFORM(data_in[dwmax:21]);
		shiftmem[2]<=data_in[22:2];ovfmem[2] <= ~`UNIFORM(data_in[dwmax:22]);
		shiftmem[3]<=data_in[23:3];ovfmem[3] <= ~`UNIFORM(data_in[dwmax:23]);
		shiftmem[4]<=data_in[24:4];ovfmem[4] <= ~`UNIFORM(data_in[dwmax:24]);
		shiftmem[5]<=data_in[25:5];ovfmem[5] <= ~`UNIFORM(data_in[dwmax:25]);
		shiftmem[6]<=data_in[26:6];ovfmem[6] <= ~`UNIFORM(data_in[dwmax:26]);
		shiftmem[7]<=data_in[27:7];ovfmem[7] <= ~`UNIFORM(data_in[dwmax:27]);
		shiftmem[8]<=data_in[28:8];ovfmem[8] <= ~`UNIFORM(data_in[dwmax:28]);
		shiftmem[9]<=data_in[29:9];ovfmem[9] <= ~`UNIFORM(data_in[dwmax:29]);
		shiftmem[10]<=data_in[30:10];ovfmem[10] <= ~`UNIFORM(data_in[dwmax:30]);
		shiftmem[11]<=data_in[31:11];ovfmem[11] <= ~`UNIFORM(data_in[dwmax:31]);
		shiftmem[12]<=data_in[32:12];ovfmem[12] <= ~`UNIFORM(data_in[dwmax:32]);
		shiftmem[13]<=data_in[33:13];ovfmem[13] <= ~`UNIFORM(data_in[dwmax:33]);
		shiftmem[14]<=data_in[34:14];ovfmem[14] <= ~`UNIFORM(data_in[dwmax:34]);
		shiftmem[15]<=data_in[35:15];ovfmem[15] <= ~`UNIFORM(data_in[dwmax:35]);
	end
	strobe_reg<= strobe_in;
end
assign data_out=shiftmem[shift];
assign ovf=ovfmem[shift];
assign strobe_out=strobe_reg;
endmodule
