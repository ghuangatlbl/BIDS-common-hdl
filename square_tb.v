`timescale 1ns / 1ns

module square_tb;

reg clk, fail=0;
integer cc;
reg debug=0;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("square.vcd");
		$dumpvars(5,square_tb);
	end
	if ($test$plusargs("debug")) debug=1;
	for (cc=0; cc<256; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
	$display("%s",fail?"FAIL":"PASS");
end

wire [10:0] v2;
square dut(.v(cc[7:0]), .v2(v2));

reg [15:0] wish;
reg fault;
always @(posedge clk) begin
	wish=(cc*cc)>>5;
	fault = (v2 > wish+1 || v2 < wish);
	if (fault) fail=1;
	if (fault | debug) $display("%d %d %d %s",cc,v2,wish,fault?"FAULT":"    .");
end

endmodule
