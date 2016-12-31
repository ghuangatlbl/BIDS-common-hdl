`timescale 1ns / 1ns

module decay_buf_tb;

reg iclk;
integer cc, errors;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("decay_buf.vcd");
		$dumpvars(5,decay_buf_tb);
	end
	errors = 0;
	for (cc=0; cc<5000; cc=cc+1) begin
		iclk=0; #5;
		iclk=1; #5;
	end
	$display("%d errors  %s", errors, errors>0 ? "FAIL" : "PASS");
	$finish();
end

reg oclk=0;
always begin
	oclk=0; #4;
	oclk=1; #4;
end

// Source emulation
reg [15:0] d_in=0;
reg stb_in=0, boundary=0, trig=0;
always @(posedge iclk) begin
	stb_in <= (cc%4)==2;
	boundary <= cc%8 == 1;
	trig <= cc%328==10;
	d_in <= cc;
end

// Readout emulation
reg [5:0] read_addr=0;
reg stb_out=0, odata_val=0;
reg [1:0] ocnt=0;
wire otrig=(ocnt==3);
integer frame=0;
always @(posedge oclk) begin
	ocnt <= ocnt+1;
	if (otrig) read_addr <= read_addr+1;
	if (otrig & (&read_addr)) frame <= frame+1;
	stb_out <= otrig;
	odata_val <= stb_out;
end

// Instantiate Device Under Test
wire [15:0] d_out;
decay_buf dut(.iclk(iclk), .oclk(oclk),
	.d_in(d_in), .stb_in(stb_in), .boundary(boundary),
	.trig(trig),
	.read_addr(read_addr), .d_out(d_out), .stb_out(stb_out)
);

// Check result
reg [15:0] prev_read=0;
reg mismatch=0, fault=0;
always @(posedge oclk) if (odata_val) begin
	prev_read <= d_out;
	mismatch = (d_out != prev_read+4);
	fault = mismatch & (read_addr != 0) & (frame>1);
	if (fault) errors = errors+1;
end

endmodule
