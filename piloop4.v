// Synthesizes to 346 slices at 130 MHz in XC3Sxxx-4 using XST-10.1i
// (with notch filter selected)

`timescale 1ns / 1ns

module piloop4 #(parameter win=18,wcoef=16,winte=10,wout=16,pkp=6,pki=6)
(clk,errin,strobe_in,kp,ki,static,ol_set,ctrl_out,strobe_out,open_locked,reset_inte,reverse);
	input clk;  // timespec 7.69 ns
	input signed [win-1:0] errin;
	input strobe_in;
	input reverse;
	input [wcoef-1:0] kp;
	input [wcoef-1:0] ki;
	input static;
	input signed [wout-1:0] ol_set;
	input reset_inte;
	output signed [wout-1:0] ctrl_out;
	output strobe_out;  // approx. 4*w+3 cycles after strobe_in
	output open_locked;

// For a given set of control words
//parameter win=18;  // width for sigin, refin
//parameter wcoef=16;    // width for kp, ki, ol_set, ctrl_out
//parameter winte=10;
//parameter wout=16;
//parameter pkp=6; // actual analog Kp and Ki scaled by 2^{-mult_shift}
//parameter pki=6; // actual analog Kp and Ki scaled by 2^{-mult_shift}

`ifndef SAT
	`define SAT(x,old,new) ((~|x[old:new] | &x[old:new]) ? x[new:0] : {x[old],{new{~x[old]}}})   // old > new, saturate old to new
`endif
`ifndef SEXT
	`define SEXT(x,old,new_old) ({{(new_old){x[old]}},x})  // old < new, sign extend to new
`endif

reg strobe_1=0,strobe_2=0,strobe_3=0,strobe_4=0,strobe_5=0;
always @(posedge clk) begin
	strobe_1 <= strobe_in;
	strobe_2 <= strobe_1;
	strobe_3 <= strobe_2;
	strobe_4 <= strobe_3;
	strobe_5 <= strobe_4;
end

reg signed [win+wcoef+winte  :0] inte_i_protected=0;
wire signed [win+wcoef+winte-1:0] inte_i= `SAT(inte_i_protected,win+wcoef+winte,win+wcoef+winte-1);
reg signed [wcoef:0] kis = 0;//reverse ? -{1'b0,ki} : {1'b0,ki};
reg signed [wcoef:0] kps = 0;//reverse ? -{1'b0,kp} : {1'b0,kp};
reg signed [win+wcoef-1:0] mult_i=0;
reg signed [win+wcoef-1:0] mult_p = 0;
always @(posedge clk) begin
	kis <= reverse ? -{1'b0,ki} : {1'b0,ki};
	kps <= reverse ? -{1'b0,kp} : {1'b0,kp};
	if (strobe_in) begin
		mult_p <= kps * errin;
		mult_i <= kis * errin;
	end
	if (strobe_1) begin
		inte_i_protected <= reset_inte ? 0 : `SEXT(inte_i,win+wcoef+winte-1,1) + `SEXT(mult_i,win+wcoef-1,winte+1);
	end
end


wire signed [win-1+wcoef-pkp:0] mult_sft_p = mult_p[win+wcoef-1:pkp];
wire signed [wout-1:0] ctrl_p;
wire signed [wout:0] ctrl_p_protected = `SEXT(ctrl_p,wout-1,1);
generate
	if (wout <= win+wcoef-pkp) begin
		assign ctrl_p = `SAT(mult_sft_p,win+wcoef-pkp-1,wout-1);
	end
	else begin
		assign ctrl_p = `SEXT(mult_sft_p,win-1+wcoef-pkp,wout-(win+wcoef-pkp));
	end
endgenerate

wire signed [win+winte-1+wcoef-pki:0] inte_sft_i=inte_i[win+wcoef+winte-1:pki];
wire signed [wout-1:0] ctrl_i;
wire signed [wout:0] ctrl_i_protected = `SEXT(ctrl_i,wout-1,1);
generate
	if (wout <= win+wcoef+winte-pki) begin
		assign ctrl_i = `SAT(inte_sft_i,win+winte+wcoef-pki-1,wout-1);
	end
	else begin
		assign ctrl_i = `SEXT(inte_sft_i,win+winte-1+wcoef-pki,wout-(win+winte+wcoef-pki));
	end
endgenerate
reg signed [wout:0] ctrl_pi_protected=0;
always @(posedge clk) begin
	if (strobe_2) ctrl_pi_protected <= ctrl_p_protected +ctrl_i_protected;
end
wire [wout-1:0] ctrl_pi = `SAT(ctrl_pi_protected,wout,wout-1);

wire open=(kps==0)&(kis==0);
reg open_d=0;
always @(posedge clk) begin
	open_d <= open;
end
assign open_locked = open_d;
assign ctrl_out = static ? ol_set : ctrl_pi;
assign strobe_out = strobe_3;
endmodule

//#test bench
//limiter anti-windup

//initial strobe_out=0;
//initial ctrl_out=0;

// PI control loop
// ctrl_out = kp*(err+ki*inte(err))
// NOTE: this version use the pole location as the ki, so the real integral factor is kp*ki

// we can use this module as P loop only but not use this module as I loop only
//
// static=0, reset_inte=0, kp=0 ki=0 lock current integrator result, update through slow read out to gui
// static reset kp ki
//    1     x   x  x   output ol_set value
//    0     1   x  x   reset integrator to 0
//    0     0   ~0 ~0  normal pi loop control
//    0     1   ~0 x   p loop only
//    0     0   0  x   lock current integrator to output, update to gui, this will help the close loop to open loop transition smoothly
//    0     0   0  0
//
// open loop operation: static=1, then adjust the ol_set in output domain, all the error keep monitoring
// start close loop: add tiny gain of kp to load current ctrl_out value to integrator, then release static
// close loop operation: increase kp, then increase ki,
// from close to open: set the kp,ki to zero, the integrator value is locked, the current output value is output through slow channel, manual (or software automatic) adjust ol_set to match the slow channel output, then switch to static
//
// Actual scaling (given the default pi_shift and mult_shift parameters)
// as determined by simulation:
//   when ki == 16000
//     a static value of 14000 on phase input becomes a slope of 26.7 per cycle
//     consistent with an integral gain of ki*2^{-23) /cycle
//   when kp == 8000
//     a step change of 14000 in phase input becomes a step of 427.75
//     consistent with a proportional gain of kp*2^{-18}
// (this does not match Gang's piloop.v)
