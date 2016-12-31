`timescale 1ns / 1ns
module crc_guts_tb;

reg clk;
integer cc, worked=0, failed=0;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("crc_guts.vcd");
		$dumpvars(5,crc_guts_tb);
	end
	for (cc=0; cc<240; cc=cc+1) begin
		clk=0;
		#5;
		clk=1;
		#5;
	end
	$display("%s",((worked>=4) && (failed==0))?"PASS":"FAIL");
end

reg clear=1, so=0, final=0, crc_latch=0;
reg [31:0] data=0;
always @(posedge clk) begin
	clear <= cc%55==0;
	data <= clear ? $random : {data[30:0],1'b0};
	so <= (cc%55)>33;
	final <= (cc%55)==50;
	if (final) begin
		crc_latch <= crc_ok;
		if (crc_ok) worked <= worked+1;
		else failed <= failed+1;
	end
end

wire g=1;  // ignore gate capability for now
wire r, c, crc_ok;
wire rx=so ? r : data[31];
// almost silly to have two, but it makes it clear that fundamentally
// a CRC works by matching state on the two sides of the comm link
crc_guts gen(.clk(clk), .gate(g), .clear(clear), .b_in(rx), .b_out(r));

crc_guts chk(.clk(clk), .gate(g), .clear(clear), .b_in(rx), .b_out(c), .zero(crc_ok));

// always @(negedge clk) $display("%d %b %b %b %b %b %b %b %b %b",
// cc, clear, final, so, gen.sr, data, rx, chk.sr, crc_ok, crc_latch);

endmodule
