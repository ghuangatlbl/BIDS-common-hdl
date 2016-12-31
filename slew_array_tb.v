`timescale 1ns / 1ns

module slew_array_tb;

reg clk, fail=0;
integer cc;
reg trace;
reg signed [4:0] ch0_max=0;
initial begin
	trace = $test$plusargs("trace");
	if ($test$plusargs("vcd")) begin
		$dumpfile("slew_array.vcd");
		$dumpvars(5,slew_array_tb);
	end
	for (cc=0; cc<700; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
	if (ch0_max != 6) begin
		$display("ch0_max = %d", ch0_max);
		fail=1;
	end
	$display("%s",fail?"FAIL":"PASS");
	$finish();
end

// Configure for 5-bit values, range -16 to 15
reg signed [4:0] in_set=0;
reg enable=0, wrap=0, tick=0;

reg h_write=0;
reg [1:0] h_addr;
always @(posedge clk) begin
	tick <= cc%11==1;
	h_write <= 0;
	h_addr <= 2'bxx;
	if (cc== 3) begin in_set <=  5; h_write <= 1; h_addr <= 1; end
	if (cc==40) enable <= 1;
	if (cc==44) begin in_set <= 14; h_write <= 1; h_addr <= 1; end
	if (cc==45) begin in_set <= 14; h_write <= 1; h_addr <= 2; end
	if (cc==46) begin in_set <= -8; h_write <= 1; h_addr <= 3; end
	if (cc==47) begin in_set <= 10; h_write <= 1; h_addr <= 0; end
	if (cc==120) begin in_set <= 0; h_write <= 1; h_addr <= 0; end
	if (cc==240) begin in_set <= -12; h_write <= 1; h_addr <= 1; end
	if (cc==586) wrap <= 1;
	if (cc==591) begin in_set <= -12; h_write <= 1; h_addr <= 2; end
end

wire signed [4:0] out_val;
slew_array #(.aw(2), .dw(5)) dut(.clk(clk),
	.h_write(h_write), .h_addr(h_addr), .h_data(in_set),
	.enable(enable), .wrap(wrap), .trig(tick),
	.outv(out_val));

reg tick_end=0;
always @(posedge clk) tick_end <= cc%11==5;

reg signed [4:0] result[0:3];
genvar gx;
reg signed [4:0] diff;
generate for (gx=0; gx<4; gx=gx+1) begin: ss
	always @(posedge clk) if (cc%11==(3+gx)) begin
		result[gx] <= out_val;
		diff = out_val-result[gx];
		if (enable && (diff>1 || diff<-1)) begin
			fail=1;
			$display("jump at %d: %d to %d", cc, result[gx], out_val);
		end
	end
end endgenerate

always @(negedge clk) begin
	if (cc==160 && result[3] != -8) fail=1;
	if (cc==200 && result[0] !=  0) fail=1;
	if (cc==220 && result[1] != 14) fail=1;
	if (cc==220 && result[2] != 14) fail=1;
	if (cc==690 && result[1] != -12) fail=1;
	if (cc==690 && result[2] != -12) fail=1;
	if (           result[1] == 15) fail=1;  // should never wrap
	if (result[0] > ch0_max) ch0_max=result[0];
	if (trace & tick_end) $display("%d %d %d %d %d", cc, result[0], result[1], result[2], result[3]);
end

integer hx;
initial begin
	for (hx=0; hx<4; hx=hx+1) begin
		dut.hbuf.mem[hx]=0;
		dut.state.mem[hx]=0;
	end
end

endmodule
