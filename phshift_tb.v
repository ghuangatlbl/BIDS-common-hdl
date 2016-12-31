`timescale 1ns / 1ns
`include "constants.vams"

module phshift_tb;

reg clk;
integer cc, errors;
integer debug=1;
initial begin
	errors = 0;
	for (cc=0; cc<600; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
	$display("%d errors  %s", errors, errors>0 ? "FAIL" : "PASS");
	$finish();
end

`define COHERENT_DEN 7
`define RF_NUM 1
integer ccr;
real volt;
real theta = `M_TWO_PI*`RF_NUM/`COHERENT_DEN;
reg signed [15:0] d_in=0, temp;
always @(posedge clk) begin
	if (cc%50==10) begin  // impulse response
		d_in <= 30000;
	end else if (cc%50>20 && cc%50<45) begin
		ccr  = cc%`COHERENT_DEN;
		volt = $sin(theta*ccr);
		temp = $floor(32000*volt+0.5);
		d_in <= temp;
	end else begin
		d_in <= 0;
	end
end

// Simple construct for testing
real phi;
real gain;
real rhs1, rhs2, alpha, beta;
reg signed [15:0] gain1=0, gain2=0;
always @(posedge clk) if (cc%50==1) begin
	phi = (cc/50)*`M_TWO_PI/12.0;
	gain = $sin(2*theta);
	if (debug>1) $display("setting up for phase shift of %.4f radians", phi);
	rhs1 = gain*$cos(phi);
	rhs2 = gain*$sin(phi);
	if (debug>1) $display("  rhs1 = %.5f   rhs2 = %.5f", rhs1, rhs2);
	// See http://recycle.lbl.gov/~ldoolitt/llrf/neariq.pdf
	// except my phase step is 2*theta
	beta = rhs2/$sin(2*theta);
	alpha = rhs1-$cos(2*theta)*beta;
	if (debug>1) $display(" alpha = %.5f   beta = %.5f", alpha, beta);
	gain1 = $floor(alpha*32767+0.5);
	gain2 = $floor(beta*32767+0.5);
end

wire signed [15:0] d_out;
phshift mut(
	.clk(clk), .d_in(d_in), .d_out(d_out),
	.gain1(gain1), .gain2(gain2)
);

integer cc2;
parameter pipe_len = 2;
real th2, sum_in_cos, sum_in_sin, sum_out_cos, sum_out_sin;
real amp_in, amp_out;
real ph_in, ph_out, ph_diff, ph_want;
always @(negedge clk) begin
	if (debug>2) $display("%d %d", d_in, d_out);
	cc2 = cc%`COHERENT_DEN;
	th2 = ccr*theta;
	if (cc%50==25) begin
		sum_in_sin = 0;
		sum_in_cos = 0;
		sum_out_sin = 0;
		sum_out_cos = 0;
	end else begin
		sum_in_sin = sum_in_sin + d_in * $sin(th2);
		sum_in_cos = sum_in_cos + d_in * $cos(th2);
		sum_out_sin = sum_out_sin + d_out * $sin(th2);
		sum_out_cos = sum_out_cos + d_out * $cos(th2);
	end
	if (cc%50==25+`COHERENT_DEN) begin
		ph_in = $atan2(sum_in_sin,sum_in_cos);
		ph_out = $atan2(sum_out_sin, sum_out_cos);
		amp_in = $sqrt(sum_in_sin*sum_in_sin+sum_in_cos*sum_in_cos)*2/`COHERENT_DEN;
		amp_out = $sqrt(sum_out_sin*sum_out_sin+sum_out_cos*sum_out_cos)*2/`COHERENT_DEN;
		ph_diff =  ph_out - ph_in;
		if (ph_diff<0) ph_diff = ph_diff + `M_TWO_PI;
		ph_want = phi + theta*pipe_len;
		if (ph_want<0) ph_want = ph_want + `M_TWO_PI;
		if (ph_want>=`M_TWO_PI) ph_want = ph_want - `M_TWO_PI;
		if (debug>1) $display("sums %6.0f %6.0f   %6.0f %6.0f",
			sum_in_cos, sum_in_sin,
			sum_out_cos, sum_out_sin);
		$display("%7.4f %7.4f   in %7.4f %6.0f   out %7.4f %6.0f",
			ph_diff, ph_want,
			ph_in, amp_in,
			ph_out, amp_out);
		if ($abs(ph_diff-ph_want)>0.0001) errors = errors+1;
	end
end

endmodule
