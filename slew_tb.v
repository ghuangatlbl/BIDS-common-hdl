`timescale 1ns / 1ns

module slew_tb;

reg clk, fail=0;
integer cc;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("slew.vcd");
		$dumpvars(5,slew_tb);
	end
	for (cc=0; cc<220; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
	$display("%s",fail?"FAIL":"PASS");
	$finish();
end

// Configure for 5-bit values, range 0 to 31
reg [4:0] in_set=0;
reg enable=0, wrap=0, tick=0;

always @(posedge clk) begin
	tick <= cc%4==1;
	if (cc==3) in_set <= 15;
	if (cc==8) enable <= 1;
	if (cc==14) in_set <= 10;
	if (cc==45) in_set <= 30;
	if (cc==136) wrap <= 1;
	if (cc==140) in_set <= 10;
end

wire [4:0] out_val;
wire motion;
slew #(.dw(5)) dut(.clk(clk), .in_set(in_set),
	.enable(enable), .wrap(wrap), .tick(tick),
	.out_val(out_val), .motion(motion));

reg [4:0] old_set=0, old_val=0;
always @(posedge clk) begin
	old_set <= in_set;
	old_val <= out_val;
end

reg [4:0] check_diff;
reg fault1, fault2;
always @(negedge clk) begin
	check_diff = old_val-out_val;
	fault1 = enable && (check_diff != 0) && (check_diff != 1) && (~(&check_diff));
	fault2 = (in_set != old_set) && (out_val != old_set);
	if (fault1|fault2) fail=1;
	if (0 & tick) $display("%d %d %d %d %d %d",cc,in_set,out_val,motion,check_diff,fault1);
end

//always @(posedge motion) $display("%d posedge motion", cc);
//always @(negedge motion) $display("%d negedge motion", cc);

endmodule
