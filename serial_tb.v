`timescale 1ns / 1ns

module serial_tb;

reg clk=0;
integer cc;
integer worked=0, failed=0, errors=0;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("serial.vcd");
		$dumpvars(5,serial_tb);
	end
	for (cc=0; cc<1000; cc=cc+1) begin
		clk=0; #10;
		clk=1; #10;
	end
	$display("%d worked", worked);
	$display("%d failed", failed);
	$display("%d errors", errors);
	$display("%s", ((worked==5) & (failed==0) & (errors==1))?"PASS":"FAIL");
end

reg [31:0] p1=0, p2=0;

reg sync=0, glitch=0;
always @(posedge clk) begin
	sync <= (cc%168==20);
	if (cc%168==19) begin
		p1 <= $random;
		p2 <= $random;
	end
	glitch <= cc==302;
end

wire bit; // serial communication itself
wire [63:0] p = {p1,p2};
serial_tx tx(.clk(clk), .tick(1'b1), .d(p), .sync(sync), .bit(bit));

wire sync_out, err_out;
wire [63:0] d_out;
serial_rx rx(.clk(clk), .tick(1'b1), .bit(bit^glitch), .sync(sync_out), .d(d_out), .err(err_out));

always @(negedge clk) if (sync_out) begin
	if (err_out) errors <= errors+1;
	else if (d_out==p) worked <= worked+1;
	else failed <= failed+1;
end

endmodule
