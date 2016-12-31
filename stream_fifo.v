`timescale 1ns / 1ns
// AXI 4 stream compatible fifo

module stream_fifo #(
	parameter AW=8,
	parameter DW=8
) (
	input clk,
	input [DW-1:0] d_in,
	input d_in_valid,
	input d_in_last,
	input read_ready,
	output [DW-1:0] d_out,
	output d_out_last,
	output d_out_valid,
	output fifo_full
);

wire fifo_empty;
wire d_out_last_i;
wire fifo_re = ~fifo_empty & read_ready;
shortfifo #(
	.dw(DW+1), .aw(AW)
) stream_tx_i (
	.clk(clk),
	.din({d_in, d_in_last}),
	.we(d_in_valid),
	.dout({d_out, d_out_last_i}),
	.re(fifo_re),
	.full(fifo_full), .empty(fifo_empty)
);
assign d_out_valid = fifo_re;
assign d_out_last = d_out_last_i & d_out_valid;

endmodule
