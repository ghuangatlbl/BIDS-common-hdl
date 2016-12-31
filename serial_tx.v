// Synthesizes to 89 slices at 156 MHz in XC3Sxxx-4 using XST-8.2i
`timescale 1ns / 1ns

module serial_tx(
	input clk,  // timespec 6.4 ns
	input tick,
	input [63:0] d,
	input sync,
	output bit
);

// Want an encoding with a CRC and an unambiguous message start.
// To keep up with the rest of the design, need to send 64 bits
// every 112 clock cycles.
//
// Let's try:
//   adjustable bit speed (based on tick input)
//   stuff a 1 before every eight data bits (8b/9b encoding)
//   include a start bit at the beginning
//   include two checksum bytes at the end
//   full message (64 data bits) is 90 clock cycles long
//   leaves 22 clock cycles between messages for frame synch
//   for decoding, run two decoders at opposite clock edges,
//   take the result that passes checksum
//   max data rate is 70 MHz * 8 / 112 = 5.0 MBytes/sec

reg run=0;
wire sync_ok = sync & ~run;  // sync coming too fast will be ignored
reg [3:0] bit_cnt=0;
reg [3:0] byte_cnt=0;
wire donebit = (bit_cnt==8) & (byte_cnt==9);
reg [4:0] zero_cnt=0;
wire donezero=~|zero_cnt;

always @(posedge clk)  if (tick) begin
	zero_cnt <= (donebit) ?5'd24:((donezero)?0:(zero_cnt-1));
end
reg start=0;
always @(posedge clk) if ((sync_ok | start & tick)&donezero) start <= sync_ok;
always @(posedge clk) if (tick) begin
	if ((start | donebit)&donezero) run <= start;
	if (run) bit_cnt <= (bit_cnt==8) ? 4'b0 : bit_cnt+1'b1;
	if (run & (bit_cnt==8)) byte_cnt <= (byte_cnt==9) ? 4'b0 : byte_cnt+1'b1;
end

wire crc;
reg [63:0] dr=0;
wire use_crc = byte_cnt>=8;
wire d1=use_crc ? crc : dr[0];
crc_guts crc_guts(.clk(clk), .gate(tick & (bit_cnt!=8)), .clear(start),
	.b_in(d1), .b_out(crc));

reg br=0;
wire one_stuff = start | bit_cnt==8;
always @(posedge clk) begin
	if (donezero) if (sync_ok | (tick & run & bit_cnt!=8)) dr <= sync_ok ? d : {1'b0, dr[63:1]};
	if (tick) br <= donezero?(one_stuff | d1):0;
end

assign bit=br;

endmodule
