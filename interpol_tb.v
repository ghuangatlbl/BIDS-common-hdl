`timescale 1ns / 1ns
`include "freq.vh"

module interpol_tb;

reg clk;
integer cc;
initial begin
	$dumpfile("interpol.vcd");
	$dumpvars(5,interpol_tb);
	for (cc=0; cc<3000; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
	$finish();
end

reg [7:0] mod=10;
reg signed [16:0] data=0;
reg signed [17:0] data7=0;
wire signed [17:0] out;
wire timing_error;

always @(posedge clk) begin
	data  <=  -8750;
	data7 <= -9333;
	mod   <= (mod==0?`CIC_PERIOD:mod)-1;
end

interpol #(.period(`CIC_PERIOD), .cntw(`CIC_CNTW))
 foo(.clk(clk), .dy(data), .dy7(data7), .strobe(mod==0),
 .y(out), .timing_error(timing_error));

always @(negedge clk) $display("%b %d %d %d %d %d %b ", foo.phase1, foo.yr, (cc-11)*1000, foo.remain, out, foo.ccnt, foo.strobe, timing_error);
endmodule
