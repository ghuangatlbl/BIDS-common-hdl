`timescale 1ns / 1ns

module iloop(clk,errin,ki,strobe_in,reverse,strobe_out,inte,reset,ctrl_out,static,ol_set);
parameter win=16;  // input width for both errin, refin kp ki
parameter wki=16;   // width  for ki
parameter pki=7; //binary point for ki
parameter winte=48;
parameter saturate_inte=1;
parameter wout=16;

input clk;
input signed [win-1:0] errin;
input [wki-1:0] ki;
input reset;
input strobe_in;
input reverse;
output strobe_out;
output signed [win+wki-pki+winte-1:0] inte;
output [wout-1:0] ctrl_out;
input [wout-1:0] ol_set;
input static;
`ifndef SAT
	`define SAT(x,old,new) ((~|x[old:new] | &x[old:new]) ? x : {x[old],{new{~x[old]}}})   // old > new, saturate old to new
`endif
`ifndef SEXT
	`define SEXT(x,old,new_old) ({{(new_old){x[old]}},x})  // old < new, sign extend to new
`endif

reg signed [wki:0] ki_s=0;
//wire signed [wki:0] ki_s = reverse ? -({1'b0,ki_r}) : {1'b0,ki_r} ;
reg signed [win+wki-1:0] mult_r=0;

reg signed [win+wki+winte:0] integrator_p=0;
wire signed [win+wki+winte-1:0] integrator;
wire signed [wout+pki-1:0] ctrl_calc;
generate
    if (saturate_inte) begin
        assign integrator=`SAT(integrator_p,win+wki+winte,win+wki+winte-1);
		assign ctrl_calc=`SAT(integrator,win+wki+winte-1,wout+pki-1);
    end
    else begin
        assign integrator=integrator_p[win+wki+winte-1:0];
		assign ctrl_calc= integrator[wout+pki-1:0];
    end
endgenerate

reg str_1=0,str_2=0,str_3=0;
always @(posedge clk) begin
	ki_s <= reverse ? -({1'b0,ki}) : {1'b0,ki} ;
	//if (strobe_in) ki_r <= ki;
	//if (str_1)
	mult_r<=errin*ki_s;
	str_1 <= strobe_in;
	str_2 <= str_1;
	str_3 <= str_2;
	if (str_1) begin
		integrator_p <= reset ? 0 : `SEXT(integrator,win+wki+winte-1,1) + {{(winte+1){mult_r[win+wki-1]}},mult_r};
	end
end

assign strobe_out =str_2;
assign inte=integrator[win+wki+winte-1:pki];
assign ctrl_out = static ? ol_set : ctrl_calc[wout+pki-1:pki];
endmodule


/*
reg signed [wki:0] ki_r=0;
reg signed [win-1:0] errin_r=0;
reg str_1=0;

always @(posedge clk) begin
	ki_r <= reverse?-{1'b0,ki}:{1'b0,ki};
	errin_r <= errin;
	str_1 <= strobe_in;
end

reg str_2=0;
//reg signed [win+wki-1:0] mult_r=0;
wire signed [win+wki-1:0] mult_r=errin*ki_s;
always @(posedge clk) begin
	//mult_r <= errin_r*ki_r;
	str_2 <= str_1;
end
reg str_3=0;

always @(posedge clk) begin
	if (strobe_in) begin
	//if (str_2) begin
		integrator_p <= reset ? 0 : `SEXT(integrator,win+wki+winte-1,1) + {{(winte+1){mult_r[win+wki-1]}},mult_r};
	end
	str_3<= str_2;
end


//assign strobe_out =str_3;
assign strobe_out =str_2;
assign inte=integrator[win+wki+winte-1:pki];
endmodule
*/
