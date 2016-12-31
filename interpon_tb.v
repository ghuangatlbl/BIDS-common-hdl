`timescale 1ns / 1ns
`include "freq.vh"

module interpon_tb;

reg clk;
integer cc;
initial begin
	// $dumpfile("interpon.vcd");
	// $dumpvars(5,interpon_tb);
	for (cc=0; cc<30000; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
	$finish();
end

integer mod=10;
reg [16:0] data=0, data_hold=0, data_hold2=0;
wire [17:0] out;

wire strobe=(mod==0);
reg [18:0] strobe_chain=0;
always @(posedge clk) begin
	data  <= $random;
	mod   <= strobe?(`CIC_PERIOD-1):(mod-1);
	strobe_chain <= {strobe_chain[17:0],strobe};
	if (strobe) data_hold <= data;
	if (strobe) data_hold2 <= data_hold;
end

interpon foo(.clk(clk), .y_in(data), .strobe(mod==0), .y_out(out));

wire print_guts=0;
always @(negedge clk) begin
	if (print_guts & strobe) $display();
	if (print_guts & ((|foo.mcount)|foo.strobe|foo.a0|foo.mdone1)) $display("interpon %b %b %b %b %d %d %d", foo.mcount, foo.a0, foo.a1, foo.a2, foo.y_hold, foo.dy, foo.accum);
	if (strobe_chain[18]) $display("%d %d %d match", $time, data_hold2, out[16:0]);
	if (~print_guts) $display("%d %d %d out", $time, out[16:0], out);
	if (foo.check1) $display("%d %d %d self_check", $time, out[16:0], foo.y_prev);
end

endmodule
