`timescale 1ns / 1ns
`include "constants.vams"
`include "freq.vh"

module cavity_tb;

reg clk;
integer cc;
integer debug=1;
reg trace;
initial begin
	trace = $test$plusargs("trace");
	for (cc=0; cc<1800; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
	$finish();
end

integer ccr;
real volt;
real theta = `M_TWO_PI*`RF_NUM/`COHERENT_DEN;
reg signed [15:0] d_in=0, temp;
always @(posedge clk) begin
	if (cc==10) begin  // impulse response
		d_in <= 30000;
	end else if (cc>30 && cc<900+`COHERENT_DEN) begin
		ccr  = cc%`COHERENT_DEN;
		volt = $sin(theta*ccr);
		temp = $floor(30000*volt+0.5);
		d_in <= temp;
	end else begin
		d_in <= 0;
	end
end

wire signed [15:0] d_out;
cavity
    #(.zp_real(0.415290410), .zp_mag(0.999400180))
  //#(.zp_real(0.414170638), .zp_mag(0.994017964))
	mut(.clk(clk), .drive(d_in), .cav(d_out)
);

always @(negedge clk) if (trace) $display("%d %d", d_in, d_out);

endmodule
