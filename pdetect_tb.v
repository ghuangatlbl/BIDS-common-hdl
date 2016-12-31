`timescale 1ns / 1ns

module pdetect_tb;

reg clk;
integer cc, fd;
reg fail=0;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("pdetect_tb.vcd");
		$dumpvars(5,pdetect_tb);
	end

	fd = $fopen("pdetect.dat");
	for (cc=0; cc<450; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
	$fclose(fd);
	$display("%s", fail ? "FAIL" : "PASS");
	$finish();
end

reg signed [17:0] ang_in=0;
always @(posedge clk) begin
	if      (cc<150) ang_in <= ang_in + 7000;
	else if (cc<300) ang_in <= ang_in - 5000;
	else if (cc<380) ang_in <= ang_in + 4000;
	else             ang_in <= ang_in - 1000;
end

wire signed [17:0] ang_out;
wire strobe_out;
pdetect #(.w(18)) mut(.clk(clk), .ang_in(ang_in), .strobe_in(1'b1),
	.ang_out(ang_out), .strobe_out(strobe_out)
);

reg signed [17:0] ang_in1=0, ang_out1=0;
always @(posedge clk) begin
	ang_in1 <= ang_in;
	ang_out1 <= ang_out;
	if (ang_out > ang_out1 + 8000 || ang_out < ang_out1 - 8000) fail=1;
	// spot-check cases read out from graph
// gnuplot> plot "pdetect.dat" using 1:2, "pdetect.dat" using 1:3
case (cc)
	10: if (ang_out != ang_in1) fail=1;
	30: if (ang_out != 131071) fail=1;
	170: if (ang_out != 131071) fail=1;
	200: if (ang_out != ang_in1) fail=1;
	250: if (ang_out != -131072) fail=1;
	300: if (ang_out != -131072) fail=1;
	350: if (ang_out != ang_in1) fail=1;
	440: if (ang_out != ang_in1) fail=1;
endcase
end

always @(negedge clk) begin
	$fdisplay(fd, "%d %d %d %d", cc, ang_in1, ang_out, mut.state);
end

endmodule
