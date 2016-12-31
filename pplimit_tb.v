`timescale 1ns / 1ns
`include "constants.vams"

module pplimit_tb;

reg clk;
integer cc;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("pplimit.vcd");
		$dumpvars(7,pplimit_tb.pl);
	end
	for (cc=0; cc<2000; cc=cc+1) begin
		clk=0; #1;
		clk=1; #1;
	end
	$finish();
end

real frf;
reg signed [7:0] xin;
wire [6:0] xout;
reg str_in;
wire str_out;
always @(posedge clk) begin
	xin=$floor(cc/10);
	str_in=($floor(cc/10)==(cc/10));
end

pplimit #(8,7) pl(.clk(clk),.in(xin),.strobe_in(str_in),.out(xout),.strobe_out(str_out));

always @(negedge clk) begin
	//$display("%d,%d,%d,%d,%d",cc,xin,ki,kp,pi1.state_pi);
	/*$display("  %13d %13d %13d %13d %13d %13d %13d %13d %13d", $time,
	mut.m12.post_filter.d2rfc1,
	mut.m12.post_filter.d2rfc2,
	mut.wangot1,
	mut.wangot2,
	mut.wangrf1,
	mut.wangca1,
	mut.wangrf2,
	mut.wangca2
	);//post_filter.dhgout);*/
end

endmodule

