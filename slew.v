`timescale 1ns / 1ns

// Note that due to internal pipelining, it's not allowed
// to wire tick high.  Maximum tick rate is clk/3.

module slew(clk,in_set,enable,wrap,tick,out_val,motion);
parameter dw=16;
input clk;
input [dw-1:0] in_set;
input enable;  // when zero, in_set propagates directly to out_val
input wrap;  // set to allow wrapping, as when value represents phase
input tick;  // step out_val towards in_set
output [dw-1:0] out_val;
output motion;  // output is slewing towards set point

reg [dw-1:0] current=0;
reg [dw:0] diff=0;
reg match=0, dir=0;
wire [dw-1:0] next = match ? current : dir ? current-1 : current+1;
always @(posedge clk) begin
	diff <= in_set - current;
	match <= diff==0;
	dir <= wrap ? diff[dw-1] : diff[dw];
	if (tick) current <= enable ? next : in_set;
end

assign out_val = current;
assign motion = ~match;

endmodule
