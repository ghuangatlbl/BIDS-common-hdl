`timescale 1ns / 1ns

// Based on, and mostly compatible with, OpenCores (Rudolf Usselmann)
// generic_fifo_dc_gray (Universal FIFO Dual Clock, gray encoded),
// downloaded from:
//    http://www.opencores.org/cores/generic_fifos/
// A previous version dropped the rst and clr inputs, as befit my FPGA needs,
// and neglected to provide wr_level and rd_level outputs.  My version is
// also coded in a more compact style.
//
// This now has rst restored (as a synchronous signal in the rd_clk
// domain), and provides rd_level output.
//
// This file counts as a derivative work, and as such Mr. Usselmann's
// copyright notice and the associated disclaimer is shown here:
/////////////////////////////////////////////////////////////////////
////                                                             ////
//// Copyright (C) 2000-2002 Rudolf Usselmann                    ////
////                         www.asics.ws                        ////
////                         rudi@asics.ws                       ////
////                                                             ////
//// This source file may be used and distributed without        ////
//// restriction provided that this copyright statement is not   ////
//// removed from the file and that any derivative work contains ////
//// the original copyright notice and the associated disclaimer.////
////                                                             ////
////     THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     ////
//// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   ////
//// TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   ////
//// FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      ////
//// OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         ////
//// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    ////
//// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   ////
//// GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        ////
//// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  ////
//// LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  ////
//// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  ////
//// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         ////
//// POSSIBILITY OF SUCH DAMAGE.                                 ////
////                                                             ////
/////////////////////////////////////////////////////////////////////

module fifo2(rd_clk, wr_clk, rst, din, we, dout, re, full, empty, wr_level, rd_level);

parameter dw=16;
parameter aw=8;

	input rd_clk;
	input wr_clk;
	input rst;  // active low
	input we;
	input re;
	input  [dw-1:0] din;
	output [dw-1:0] dout;
	output reg full, empty;
	output [1:0] wr_level, rd_level;

// Logic for write pointer -- very simple
reg  [aw:0] wp_bin=0, wp_gray=0;
wire [aw:0] wp_bin_next  = wp_bin + 1'b1;
wire [aw:0] wp_gray_next = wp_bin_next ^ {1'b0, wp_bin_next[aw:1]};
always @(posedge wr_clk) if (we | ~rst) begin
	wp_bin  <= ~rst ? 0 : wp_bin_next;
	wp_gray <= ~rst ? 0 : wp_gray_next;
end

// Logic for read pointer -- very simple
reg  [aw:0] rp_bin=0, rp_gray=0;
wire [aw:0] rp_bin_next  = rp_bin + 1'b1;
wire [aw:0] rp_gray_next = rp_bin_next ^ {1'b0, rp_bin_next[aw:1]};
always @(posedge rd_clk) if (re | ~rst) begin
	rp_bin  <= ~rst ? 0 : rp_bin_next;
	rp_gray <= ~rst ? 0 : rp_gray_next;
end

// Instantiate actual memory
dpram #(.aw(aw), .dw(dw)) mem(
	.clkb(rd_clk), .addrb(rp_bin[aw-1:0]), .doutb(dout),
	.clka(wr_clk), .addra(wp_bin[aw-1:0]), .dina(din), .wena(we));

// Send read pointer to write clock domain
reg [aw:0] rp_s=0; always @(posedge wr_clk) rp_s <= rp_gray;
wire [aw:0] rp_bin_x = rp_s ^ {1'b0, rp_bin_x[aw:1]};  // convert gray to binary

// Send write pointer to read clock domain
reg [aw:0] wp_s=0; always @(posedge rd_clk) wp_s <= wp_gray;
wire [aw:0] wp_bin_x = wp_s ^ {1'b0, wp_bin_x[aw:1]};  // convert gray to binary

// Finally can compute the hard part, the status flags
wire [aw:0] block = {1'b1, {aw{1'b0}}};
initial empty=1;
always @(posedge rd_clk) empty <=
	(wp_s == rp_gray) | (re & (wp_s == rp_gray_next));
initial full=0;
always @(posedge wr_clk) full <=
	(wp_bin == (rp_bin_x ^ block)) |
	(we & (wp_bin_next == (rp_bin_x ^ block)));

// Registered Level Indicators
reg [1:0] wr_level;
reg [aw-1:0] rp_bin_xr=0, d1=0;
reg full_wc=0;
always @(posedge wr_clk) begin
	full_wc <= full;
	rp_bin_xr <= ~rp_bin_x[aw-1:0] + {{aw-1{1'b0}}, 1'b1};
	d1 <= wp_bin[aw-1:0] + rp_bin_xr[aw-1:0];
	wr_level <= {d1[aw-1] | full | full_wc, d1[aw-2] | full | full_wc};
end

reg [1:0] rd_level=2'b11;
reg [aw-1:0] wp_bin_xr=0, d2=0;
reg full_rc=0;
always @(posedge rd_clk) begin
	wp_bin_xr <= ~wp_bin_x[aw-1:0];
	d2 <= rp_bin[aw-1:0] + wp_bin_xr[aw-1:0];
	full_rc <= full;
	rd_level <= full_rc ? 2'h0 : {d2[aw-1] | empty, d2[aw-2] | empty};
end

endmodule
