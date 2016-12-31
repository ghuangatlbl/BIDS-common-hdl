`timescale 1ns / 1ns

module piloop2_tb;

reg clk;
integer cc;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("piloop2.vcd");
		$dumpvars(3,piloop2_tb.pi1);
	end
	for (cc=0; cc<4000; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
	$finish();
end

reg signed [17:0] xin=0,ref=0;
reg [15:0] kp=0,ki=0,static_set=1000;
wire fake_data=((cc%28)==10);
reg str_in=0;
reg [6:0] lo128=0;
always @(posedge clk) begin
	str_in<=fake_data;
	// if (fake_data) xin<=xin-10;
	if (cc==200)  ki<=16000;
	if (cc==200)  kp<=8000;
	if (cc==1000) xin<=14000;
	if (cc==3500) xin<=-1000;
	if (cc==3900) ki<=0;
	lo128 <= lo128 + 1;
end

wire str_out;
wire signed [15:0] corr;
piloop2 #(18,16) pi1(.clk(clk),.sigin(xin),.refin(ref),.kp(kp),.ki(ki),
	.static_set(static_set),.strobe_in(str_in),.reverse(1'b1),
	.notch_enable(1'b1), .lo128(lo128),
	.ctrlout(corr),.strobe_out(str_out));

always @(negedge clk) begin
	if (str_in) $display("input %d", xin);
	if (str_out) $display("output %d", corr);
	if (pi1.mult_done) $display("mult result %d", pi1.mult_result);
	if (pi1.add_done ) $display(" add result %d", pi1.add_result);
end

endmodule
