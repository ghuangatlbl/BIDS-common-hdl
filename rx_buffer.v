// Synthesizes to 125 slices and 2 block RAMs at 140 MHz in XC3Sxxx-4 using XST-7.1i
// Note that I can't use my timespec hack to automagically
// generate a .ucf file here, because there are _two_ clock domains.

// Common code for all boards that use the CY7C68013 in GPIF Master
// mode for a USB-2.0 interface; derived from USRP.  Compatible with
// Avnet Virtex-4 and Virtex-5 evaluation boards, LBNL UXO, and
// LBNL LLRF4 boards.  Supported on the host side by xguff.

`timescale 1ns / 1ns

module rx_buffer (
	// Interface to CY7C68013 GPIF
	input usbclk,
	output [15:0] usbdata,
	input RD,
	output wire have_pkt_rdy,

	// Additional signals to controller
	output reg rx_overrun,
	input clear_status,

	// Supply-side
	input rxclk,
	input rxstrobe,
	input wire [15:0] rxdata,
	input rst,

	// Debug
	output [15:0] debugbus
);

	initial rx_overrun=0;

	// 257 Bug Fix
	reg [8:0] read_count;
	wire rd_gate = ~read_count[8];
	always @(negedge usbclk)
		read_count <= RD ? (read_count + rd_gate) : 0;

	// Debug
	reg rxfreq=0;
	always @(posedge rxclk) if (rxstrobe) rxfreq <= ~rxfreq;

	// Detect overrun
	wire fifo_full;
	always @(posedge rxclk) begin
		if ((rxstrobe & fifo_full) | clear_status) begin
			rx_overrun <= rxstrobe & fifo_full;
		end
	end

	// try OpenCores FIFO
	wire obuf_ready;
	wire fifo_empty;
	wire [1:0] fifo_wr_level, fifo_rd_level;
	wire [15:0] fifo_out;
	wire precharge = ~fifo_empty & ~obuf_ready;
	wire fifo_read = RD & rd_gate | precharge;
	fifo2 #(.dw(16),.aw(11)) usb_fifo(
		.rd_clk(~usbclk), .wr_clk(rxclk), .rst(rst), /* .clr(1'b0), */
		.din(rxdata), .we(rxstrobe), .dout(fifo_out),
		.re(fifo_read),
		.full(fifo_full), .empty(fifo_empty),
		.wr_level(fifo_wr_level), .rd_level(fifo_rd_level));

	// one stage of latch to keep output latency down
	// not sure why the Avnet board doesn't need it.
	// Is this a CY7C68013 vs. CY7C68013A issue?
`ifdef TARGET_s3
	reg obuf_filled;
	reg fifo_read_late;
	reg [15:0] fifo_out2;
	always @(negedge usbclk or negedge rst) if (~rst) begin
		fifo_read_late <= 0;
		obuf_filled <= 0;
	end else begin
		fifo_read_late <= fifo_read;
		if (fifo_read_late) fifo_out2 <= fifo_out;
		if (fifo_read) obuf_filled <= 1;
	end
	assign usbdata = fifo_read_late ? fifo_out : fifo_out2;
	assign obuf_ready = obuf_filled;
`else
	assign usbdata = fifo_out;
	assign obuf_ready = 1;  // never precharge
`endif

	assign have_pkt_rdy = fifo_rd_level != 2'b11;

	assign debugbus[0] = RD;
	assign debugbus[1] = fifo_full;
	assign debugbus[2] = rxfreq;
	assign debugbus[4:3] = fifo_rd_level;
	assign debugbus[5] = rx_overrun;
	assign debugbus[15:6] = 0;

endmodule
