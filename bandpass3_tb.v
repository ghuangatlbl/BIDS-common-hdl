`timescale 1ns / 1ns
`include "constants.vams"

module bandpass3_tb;

reg clk;
integer cc;
// Integer values for cm1 and d are
// scaled by 2^17 from real value.  See cset.m
reg signed [16:0] cm1, d;
initial begin
	if (!$value$plusargs("cm1=%d",  cm1))  cm1 = 7510;
	if (!$value$plusargs("d=%d",    d  ))  d   = -23395;
	for (cc=0; cc<500; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
	$finish();
end

`define COHERENT_DEN 7
`define RF_NUM 1
integer ccr;
real volt;
reg signed [15:0] ind=0, temp=0;
always @(posedge clk) begin
	if (cc==10) begin  // impulse response
		ind <= 30000;
	end else if (cc>200 && cc<300) begin  // check for clipping: max amp at center
		ccr  = cc%`COHERENT_DEN;
		volt = $sin(`M_TWO_PI*`RF_NUM*ccr/`COHERENT_DEN);
		temp = $floor(3500*volt+0.5);
		ind <= temp;
	end else begin
		ind <= 0;
	end
end

wire signed [17:0] outd;
bandpass3 mut(
	.clk(clk), .inp(ind), .oe(1'b1), .zerome(1'b0), .out(outd),
	.cm1(cm1), .d(d)
);

always @(negedge clk) $display("%d %d", ind, outd);

endmodule
