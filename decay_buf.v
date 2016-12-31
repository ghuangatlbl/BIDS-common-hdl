`timescale 1ns / 1ns

// The basic rule here is: it's OK to drop data, and it's OK to
// duplicate data, but it's not allowed to corrupt data.  Corrupt
// in this case means give a record that does not correspond to
// a single contiguous stream of triggered input.
module decay_buf(
	// source side
	input iclk,
	input [15:0] d_in,
	input stb_in,  // 2-cycles
	input boundary,  // between blocks of input strobes
	input trig,  // single-cycle

	// readout side
	input oclk,
	input [5:0] read_addr,
	output [15:0] d_out,
	input stb_out
);

// 64 words of 16 bits (32 each I and Q samples), double-buffered

// source side control logic
wire flag_return;   // handshake from readout side
reg [5:0] write_addr=0;
reg pend=0, run=0, wbank=0, flag_return_x=0;
wire source_ok = ~wbank ^ flag_return_x;
wire end_write_addr = &write_addr;
always @(posedge iclk) begin
	flag_return_x <= flag_return;  // Clock domain crossing
	if (stb_in & run) write_addr <= write_addr+1;
	if (stb_in & end_write_addr) run <= 0;
	if (stb_in & end_write_addr) wbank <= ~wbank;
	if (trig & source_ok | boundary) pend <= trig & source_ok;
	if (pend & boundary) run <= 1;
end
wire flag_send=wbank;  // says "I want to write bank foo"
// Handshake means "OK, I won't read bank foo"

// readout side control logic
reg flag_send_x=0;
reg rbank=0;  // really complement
wire end_read_addr = &read_addr;
always @(posedge oclk) begin
	flag_send_x <= flag_send;  // Clock domain crossing
	if (stb_out & end_read_addr) rbank <= flag_send_x;
end
assign flag_return = rbank;

// data path is simply a dual-port RAM
dpram #(.aw(7), .dw(16)) mem(.clka(iclk), .clkb(oclk),
	.addra({wbank,write_addr}), .dina(d_in), .wena(stb_in & run),
	.addrb({~rbank,read_addr}), .doutb(d_out)
);

endmodule
