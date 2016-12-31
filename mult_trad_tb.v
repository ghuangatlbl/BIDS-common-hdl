`timescale 1ns / 1ns

module mult_trad_tb;

reg clk;
integer cc;
integer fails=0;
initial begin
	for (cc=0; cc<481; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
	$display("%s",fails==0?"PASS":"FAIL");
	$finish();
end

parameter w=32;
reg [5:0] div=0;
reg load=0;
reg [w-1:0] X={w{1'b1}};
reg signed [w-2:0] Y={(w-2){1'b1}};
wire s;  // feedback from mut
always @(posedge clk) begin
	div  <= div+1;
	load <= div==4;
	if (s) begin
		X = X - 16000*{w-16{1'b1}};
		Y = Y -  5000*{w-16{1'b1}};
	end
end

wire signed [2*w-1:0] result;
mult_trad #(w) mut(.clk(clk), .X(X), .Y(Y), .load(load), .R(result), .strobe(s));

reg single;
reg signed [w+1:0] sX;
always @(negedge clk) begin
	// $display("%d %d %d %d %d", load, s, mut.A, mut.B, result);
	if (s) begin
		sX = X;
		single = sX*Y==result;
		if (~single) fails=fails+1;
		$display("%d * %d = %d%s", X, Y, result, single?"      OK":"  wrong!");
	end
end

endmodule
