`timescale 1ns / 1ns

module trip_tb;

reg clk, fail=0;
integer cc;
reg debug=0;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("trip.vcd");
		$dumpvars(5,trip_tb);
	end
	if ($test$plusargs("debug")) debug=1;
	for (cc=0; cc<128; cc = cc + 1) begin
		clk=0; #5;
		clk=1; #5;
	end
	$display("final state %s, peak value %d", tripped ? "tripped" : "running", peak_val);
	fail = ~tripped || peak_val != 1167;
	$display("%s",fail?"FAIL":"PASS");
end

integer i;
reg signed [6:0] v1, v2, v3, v4;
reg signed [8:0] vs, vi=0;
reg ngate, gate=0;
always @(posedge clk) begin
	// Central limit theorem says vs will look superficially Gaussian
	v1 = $random;
	v2 = $random;
	v3 = $random;
	v4 = $random;
	vs = v1+v2+v3+v4;
	ngate = (cc%7) < 2;
	gate <= (cc%7)==0;
	vi <= ngate ? vs : 9'bx;
end
wire tripped;
wire [11:0] peak_val;
trip trip(.clk(clk), .inval(vi), .gate(gate),
	.trip_thresh(12'd600), .reset(cc<5 || cc==92), .clear(cc<5 || cc==64),
	.tripped(tripped), .peak_val(peak_val)
);

always @(negedge clk) begin
	if (cc==64) $display("clearing peak_val");
	if (cc==92) $display("clearing tripped state");
	if (debug) $display("%d %d %d %d %d  %d %d %d %d", cc, vi, gate, trip.last_sq, trip.sum_sq, trip.trip, trip.gate_d5, tripped, peak_val);
end

endmodule
