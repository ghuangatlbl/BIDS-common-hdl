// Single-clock-domain bridge from a narrow address ("bn")
// local bus to a wide address (16-bit "bw") local bus.
// Both busses use 32-bit wide data.
//
// Larry Doolittle, LBNL, January 2014
//
// Only writes are considered.
// Also think about providing read access on the wide side,
// pushing data out either on the slow bus or as a waveform.
//
// Specific application is USB for the narrow address side,
// and the statespace engine on the wide address side.
//
// ABI from the narrow side:
//  Address 0: wide address and configuration
//       3 bits reserved
//       1 bit  double
//      12 bits count
//      16 bits address
//  Address 1: data
// Of course, the single address bit is assumed to be taken from
// a larger address bus, with the write strobe pre-decoded based
// on the other address bits.
//
// Assumes the writes from the narrow side are "rare", at least
// not consecutive.  Certainly true in the USB->JTAG->FPGA case.
// See the fault output.
//
// If "double" is set in the configuration word (mask 0x10000000),
// each single 32-bit write will be converted to two 16-bit writes
// on the wide address bus.  The low half-word is written first,
// and in fact the upper half-word is not masked out on that cycle.
// The second half-word, containing the original upper half-word
// moved to the lower slot, is padded with zeros in the following cycle.
// In this case, the "count" part of the configuration word refers to
// the number of 32-bit input words, not the (two times larger) number
// of output bus writes.  This two-cycle write is atomic in the context
// of the statespace engine.
//
// The "fault" output is a non-latching indicator of a fault
// in the write timing.  It is based only on the count value and
// write pulses, independent of the data and address.
//
// Two faults are detected:
//   write pulses on consecutive clock cycles
//   data write cycles when this subsystem is in the "complete" state.
//
// The "complete" output is an indicator that the desired number
// of writes has taken place.

`timescale 1ns / 1ns

module busbridge(
	input clk,  // timespec 8.0 ns
	input [31:0] bn_data,
	input        bn_addr,
	input        bn_write,

	output [31:0] bw_data,
	output [15:0] bw_addr,
	output        bw_write,

	output fault,
	output complete
);

reg [31:0] bw_data_r=0;
reg [15:0] bw_addr_r=0;
reg [11:0] bw_cnt=0;
reg        double=0;
reg        bn_write1=0, bw_write_r=0, bw_write_r1=0;
reg        fault_r=0, complete_r=0;
wire write_addr = bn_write & ~bn_write1 & (bn_addr==0);
wire write_data = bn_write & ~bn_write1 & (bn_addr==1);
always @(posedge clk) begin
	bw_write_r <= 0;
	fault_r <= 0;
	if (write_addr) {double,bw_cnt,bw_addr_r} <= bn_data;
	if (write_data) begin
		bw_data_r <= bn_data;
		if (~complete_r) bw_write_r <= 1;
		if (complete_r) fault_r <= 1;
	end
	if (bw_write) bw_addr_r <= bw_addr_r + 1;
	if (bw_write_r) bw_cnt <= bw_cnt - 1;
	if (bw_write_r & double) bw_data_r <= {16'b0,bw_data_r[31:16]};
	complete_r <= bw_cnt == 0;
	bw_write_r1 <= bw_write_r;
	bn_write1 <= bn_write;
	if (bn_write & bn_write1) fault_r <=1;
end

assign bw_data  = bw_data_r;
assign bw_addr  = bw_addr_r;
assign bw_write = bw_write_r | (bw_write_r1 & double);
assign complete = complete_r;
assign fault = fault_r;

endmodule
