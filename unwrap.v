`timescale 1ns / 1ns
module unwrap(clk,sync_in,d_in,wrapset,wrapsetvalue,sync_out,d_out,wrapout);
parameter win=17;
parameter wpi2in=1;
parameter wout=25;
input clk;   // timespec 8.4 ns
input sync_in;  // two pulses in a row
input signed [win-1:0] d_in;
input wrapset;
input [wout-win+wpi2in-2:0] wrapsetvalue;
output sync_out;
output signed [wout-1:0] d_out;
output [wout-win+wpi2in-2:0] wrapout;

reg sync1=0;
reg signed [win-1:0] old1=0;
reg signed [win:0] diff1=0;
always @(posedge clk) begin
	if (sync_in) begin
		diff1 <= {d_in[win-1],d_in} - {old1[win-1],old1};
		old1 <= d_in;
	end
	sync1 <= sync_in;
end

reg sync2=0;
reg signed [wout-win+wpi2in-2:0] wrap1=0;
reg signed [win-1:0] old1_d=0;
wire overflow = ~((~|diff1[win:win-wpi2in])||(&diff1[win:win-wpi2in]));
//(diff1[win])^(diff1[win-1]);
wire signed [wout-win+wpi2in-2:0] delta = overflow ? (diff1[win] ?1: {(wout-win+wpi2in-1){1'b1}} ): {(wout-win+wpi2in-1){1'b0}};
//wire signed [wout-win-1:0] delta = overflow ? (diff1[win] ?1: {(wout-win){1'b1}} ): {(wout-win){1'b0}};
always @(posedge clk) begin
	if (sync1) begin
		wrap1 <= $signed(wrapset? wrapsetvalue:0) +(wrap1 + delta);
		old1_d <= old1;
	end
	sync2 <= sync1;
end
/*
reg sync3=0;
reg [wout-1:0]d_out_r=0;
always @(posedge clk) begin
	if (sync2) begin

	end
	sync3 <= sync2;
end
*/
assign sync_out = sync2;
assign d_out ={wrap1,{(win-wpi2in+1){1'b0}}}+{{(wout-win){old1_d[win-1]}}, old1_d};
assign wrapout = wrap1;
endmodule
