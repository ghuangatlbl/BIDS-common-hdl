`timescale 1ns / 1ns
module crc_guts(
	input clk,
	input gate,
	input clear,
	input b_in,
	output b_out,
	output zero
);
// default is CRC-16-CCITT
// poly high order bit implicitly one
// http://en.wikipedia.org/wiki/Cyclic_redundancy_check
parameter wid=16;
parameter poly=16'h1021;
parameter init=16'hffff;

reg [wid-1:0] sr=0;
wire fb=sr[wid-1]^b_in;
always @(posedge clk) if (gate)
	sr <= clear ? init : ({sr[wid-2:0],1'b0} ^ ({wid{fb}} & poly));
assign b_out = sr[wid-1];
assign zero = ~(|sr);
endmodule
