`timescale 1ns / 1ns
module pplimit(clk,in,strobe_in,out,strobe_out);
parameter w_in=16;
parameter w_out=10;
input clk;
input signed [w_in-1:0] in;
input strobe_in;
output signed [w_out-1:0] out;
output strobe_out;

reg signed [w_out-1:0] outreg=0;
reg str_out_reg=0;
always @(posedge clk) begin
	if (strobe_in)
outreg <= in[w_in-1]?((&in[w_in-2:w_out-1])?{1'b1,in[w_out-2:0]}:{1'b1,{(w_out-1){1'b0}}}) :((|in[w_in-2:w_out-1])?{1'b0,{(w_out-1){1'b1}}}:{1'b0,in[w_out-2:0]});
	str_out_reg <= strobe_in;
end
assign out =  outreg;
assign strobe_out=str_out_reg;


endmodule
