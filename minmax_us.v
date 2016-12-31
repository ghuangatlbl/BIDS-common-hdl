`timescale 1ns / 1ns

// unsigned variant of minmax
module minmax_us(clk,xin,reset,xmin,xmax);
parameter width=14;

	input clk;
	input [width-1:0] xin;
	input reset;
	output [width-1:0] xmin;
	output [width-1:0] xmax;

reg [width-1:0] xmin_r={width{1'b1}};
reg [width-1:0] xmax_r={width{1'b0}};
wire [width-1:0] max_plus = {(width){1'b1}};
always @ (posedge clk) begin
	xmax_r <= reset ? (~max_plus) : (xin>xmax_r) ? xin : xmax_r;
	xmin_r <= reset ? ( max_plus) : (xin<xmin_r) ? xin : xmin_r;
end
assign xmax = xmax_r;
assign xmin = xmin_r;

endmodule
