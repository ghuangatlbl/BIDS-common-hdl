`timescale 1ns / 1ns

module shortfifo_tb;

reg clk;
integer cc;
reg fail=0;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("shortfifo.vcd");
		$dumpvars(5,shortfifo_tb);
	end
	for (cc=0; cc<150; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
	$display("%s", fail ? "FAIL" : "PASS");
end

reg [7:0] din=0;
reg w, we=0, re1=0;
reg [1:0] w2;
wire full, empty;
always @(posedge clk) begin
	if (cc < 100) w = $random & ~full;
	else begin w2 = $random; w = &w2 & ~full; end
	if (w) din <= din+1;
	we <= w;
	re1 <= $random;
end
wire re = re1 & ~empty;

wire [7:0] dout;
shortfifo #(.dw(8), .aw(3)) dut (.clk(clk),
	.din(din), .we(we),
	.dout(dout), .re(re),
	.full(full), .empty(empty)
);

reg [7:0] oldout = 0;
wire [7:0] delta = dout-oldout;
always @(posedge clk) if (re) begin
	oldout <= dout;
	if (delta != 1) fail=1;
end

endmodule
