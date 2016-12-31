`timescale 1ns / 1ns

module simple_cic_tb;

reg clk, fail=0;
integer cc;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("simple_cic.vcd");
		$dumpvars(5,simple_cic_tb);
	end
	for (cc=0; cc<256; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
	$display("%s",fail?"FAIL":"PASS");
end

reg reset=0, g_in=0;
reg signed [15:0] d_in;

always @(posedge clk) begin
	d_in <= cc*75+200;
	g_in <= cc%2==0;
end
wire g_out;
wire signed [17:0] d_out;
simple_cic dut(.clk(clk), .reset(reset), .g_in(g_in),
	.g_out(g_out), .d_in(d_in), .d_out(d_out));

// No checks yet, will always pass

endmodule
