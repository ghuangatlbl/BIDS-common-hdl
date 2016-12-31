`timescale 1ns / 1ns

module serial_rx(
	input clk,  // timespec 6.4 ns
	input tick,
	input bit,
	output sync,
	output [63:0] d,
	output err  // flag valid at the time of sync
);

// For protocol documentation, see serial_tx.v

// The key to this protocol is that bit-stuffing in the
// transmitter guarantees that there will never be nine
// zeros in a row during the message, but there are 21
// zeros in a row separating every pair of messages.
// So it's easy to find a message start, just look for
// at least 9 zeros (with zero_cnt) followed by a one.

// Consider watching for missing stuffed ones, and
// forcing an error if detected.

reg run=0;
reg [3:0] bit_cnt=0;
reg [3:0] byte_cnt=0;
wire done = (bit_cnt==8) & (byte_cnt==9);
reg [3:0] zero_cnt=0;
wire start = (zero_cnt==9) & bit;
always @(posedge clk) if (tick) begin
	zero_cnt <= bit ? 4'b0 : ((zero_cnt==9) ? 4'd9 : zero_cnt+1'b1);
	if (start | done) run <= start;
	if (run) bit_cnt <= (bit_cnt==8) ? 4'b0 : bit_cnt+1'b1;
	if (run & (bit_cnt==8)) byte_cnt <= (byte_cnt==9) ? 4'b0 : byte_cnt+1'b1;
end

wire crc_zero;
reg [63:0] dr=0;
wire use_crc = byte_cnt>=8;
crc_guts crc_guts(.clk(clk), .gate(tick & (bit_cnt!=8)), .clear(start),
	.b_in(bit), .zero(crc_zero));

reg br=0;
always @(posedge clk) if (tick) begin
	if (run & (bit_cnt!=8) & ~use_crc ) dr <= {bit, dr[63:1]};
end

reg sync_r=0, err_r=0;
always @(posedge clk) begin
	sync_r <= done & tick;
	err_r  <= ~crc_zero;
end
assign sync = sync_r;
assign err  = err_r;
assign d = dr;

endmodule
