`timescale 1ns / 1ns

// Uber-simple mapping of a UDP packet to a register read/write port.
// Lead with 64 bits of padding (sequence number, ID, nonce, ...),
// then alternate 32 bits of control+address with data.
// Stick with 24 bits of address, leave 8 bits for control.
// Only one of those control bits is actually used, it's the R/W line.
// Every packet is returned to the sender with the read data filled in.
// Local bus read latency is fixed, configurable at compile time.
// Uses standard network byte order (big endian).
// XXX Needs work on interlocking if the output FIFO fills up.

module raw_gateway(
	clk,
	rx_ready,
	rx_strobe,
	rx_crc,
	packet_in,
	tx_ack,
	tx_strobe,
	tx_req,
	tx_len,
	packet_out,
	// read data from memory
	read_strobe,
	data_in,
	// wirte data to memory
	data_out,
	data_out_gate,
	tx_req_in,
	tx_len_in
);
parameter jumbo_dw=14;
parameter NUM_BYTE=8; // NUM_BYTE must in { 1, 2, 4, 8, 16}
parameter TXLEN_WIDTH=16;


`ifdef SIMULATE
parameter MAX_ONE_TXLEN=8;
parameter BURST_LEN=16'd16;
parameter PACKET_LEN=11'd40;
`else
parameter MAX_ONE_TXLEN=1024;
parameter BURST_LEN=16'd1024;
parameter PACKET_LEN=11'd1032;
`endif

wire [TXLEN_WIDTH-1:0] temp=MAX_ONE_TXLEN;

input clk;   // timespec 6.8 ns
// interface for packet reception
input rx_ready;
input rx_strobe;
input rx_crc;  // ignored
input [7:0] packet_in;
// interface for packet transmission
input tx_ack;
input tx_strobe;
output reg tx_req=1'b0;
output [jumbo_dw-1:0] tx_len;
output [7:0] packet_out;

// local bus: read data from memory
output read_strobe;  // read strobe from ethernet
input [NUM_BYTE*8-1:0] data_in;

// local bus: write data to memory
output reg [NUM_BYTE*8-1:0] data_out={NUM_BYTE*8{1'b0}};
output reg data_out_gate=1'b0;

input [TXLEN_WIDTH-1:0] tx_len_in;

input tx_req_in;  // tx_req_in  send to gateway then send to gmii



initial tx_req=1'b0;

// octet are shift regs indicate i/oword byte shift sequence
reg [NUM_BYTE-1:0] octet_rx={NUM_BYTE{1'b0}};
reg [NUM_BYTE-1:0] octet_tx={NUM_BYTE{1'b0}};
// i/o pipe for rx tx
reg [NUM_BYTE*8-1:0] iwords={NUM_BYTE*8{1'b0}};
reg [NUM_BYTE*8-1:0] owords={NUM_BYTE*8{1'b0}};
// packet head
reg [63:0] packet_head=64'b0;
// tx_req_in reg
reg tx_req_in_r=1'b0;

// use rx_ready_cnt to find when is packet head, when is packet data
reg [15:0] rx_ready_cnt=16'b0;
// cnt for each tx: the same idea as rx_ready_cnt
reg [15:0] tx_cnt=16'b0;
// tx_strobe delay one cycle
reg tx_strobe_d=1'b0;

// records the length of data need to be send, updated after every tx
reg [TXLEN_WIDTH+3:0] tx_len_in_r={(TXLEN_WIDTH+3){1'b0}};
// actual send length of data at one time
wire [10:0] packet_len_load=(tx_len_in_r>MAX_ONE_TXLEN) ? MAX_ONE_TXLEN:tx_len_in_r;
// packet_len_load +8 = packet_len  take packet head (8 bytes) into account
reg [10:0] packet_len=11'b0;

// iword -> data_out strobe
wire data_strobe;

// get 4 delayed tx_req_in_r
reg [3:0] tx_req_in_pipe=4'b0;
// when ~busy_tx & after save packet head we can enable tx
reg tx_ena=1'b0;

wire tx_done_pre=(tx_cnt=={5'b0,packet_len});
reg tx_done_pre_d=1'b0;
wire tx_done=tx_done_pre&(~tx_done_pre_d);
reg tx_req_done=1'b0;
wire [TXLEN_WIDTH+3:0] tx_len_in_byte= (NUM_BYTE==1) ? {4'b0,tx_len_in}:
									   ((NUM_BYTE==2) ? {3'b0,tx_len_in,1'b0} :
									   ((NUM_BYTE==4) ? {2'b0,tx_len_in,2'b0} :
									   ((NUM_BYTE==8) ? {1'b0,tx_len_in,3'b0} :
									   ((NUM_BYTE==16) ? {tx_len_in,4'b0} :
									   {(TXLEN_WIDTH+3){1'b0}}))));

reg busy_tx=1'b0;
// indicate loading packet head
reg rx_head_refreshing=1'b0;
reg rx_head_refreshing_d=1'b0;
always @(posedge clk) begin
	rx_head_refreshing_d<=rx_head_refreshing;
end
wire trig_tx=rx_head_refreshing_d&(~rx_head_refreshing);

always @(posedge clk) begin
	tx_done_pre_d<=tx_done_pre;
end

// the packet_in is packet head
wire read_head_flag=(rx_ready_cnt<16'd8)&rx_strobe;
// the packet_in is packet data
wire rx_data_flag=(~read_head_flag)&rx_strobe;
reg rx_data_flag_d=0;

always @(posedge clk) begin
	rx_data_flag_d<=rx_data_flag;
end

// octet shift procedure
always@(posedge clk) begin
	if (rx_ready&(~busy_tx)) begin
		octet_rx<={{NUM_BYTE-1{1'b0}},1'b1};
		rx_head_refreshing<=1'b1;
	end
	else if (rx_data_flag) begin
		octet_rx<={octet_rx[NUM_BYTE-2:0],octet_rx[NUM_BYTE-1]};
		rx_head_refreshing<=1'b0;
	end
end
always@(posedge clk) begin
	if (tx_ack) begin
		octet_tx<={{NUM_BYTE-1{1'b0}},1'b1};
	end
	else if (tx_strobe) begin
		octet_tx<={octet_tx[NUM_BYTE-2:0],octet_tx[NUM_BYTE-1]};
	end
end

//  cnt for rx_ready
always @(posedge clk) begin
	if (rx_ready) begin
		rx_ready_cnt<=16'b0;
	end
	else if(rx_strobe)
		rx_ready_cnt<=rx_ready_cnt+16'b1;
end


// tx_cnt
always @(posedge clk) begin
	if (tx_ack) begin
		tx_cnt<=16'b0;
	end else if (tx_strobe&(~tx_done))
		tx_cnt<=tx_cnt+16'b1;
	else
		tx_cnt<=tx_cnt;
end

// packet_head
always @(posedge clk) begin
	if (read_head_flag&(~busy_tx))  // need modify
		packet_head<={packet_head[55:0],packet_in}; // need modify
end

// packet_data
always@(posedge clk) begin
	if (rx_data_flag)
		iwords<={iwords[NUM_BYTE*8-9:0],packet_in};
end
// data_out
always@(posedge clk) begin
	if (data_strobe)
		data_out<=iwords;
	data_out_gate<=data_strobe;
end

always @(posedge clk) begin
	tx_strobe_d<=tx_strobe;
end
// owords
always @(posedge clk) begin
	if (tx_strobe&~tx_strobe_d)
		owords<={packet_head};
	else if (tx_strobe &(tx_cnt>16'd5)&octet_tx[0])
		owords<=data_in;
	else
		owords<={owords[55:0],8'b0};
end

// load tx_len_in_r
wire busy_clear_flag=tx_done&(~|tx_len_in_r);
always @(posedge clk) begin
	tx_req_in_r<=((~tx_req_in_r)&(~busy_tx)&(tx_ena)) ? tx_req_in : tx_done ? ~busy_clear_flag :1'b0;
	busy_tx<=(~busy_tx) ? tx_req_in_r : (~busy_clear_flag);
	tx_ena<=(~tx_ena) ? (trig_tx&(~busy_tx)) : ~tx_req_in_r;

	if (tx_req_in_r&(~busy_tx)) begin
		tx_len_in_r<=tx_len_in_byte;
	end
	else if (tx_req_in_pipe[0]) begin
		tx_len_in_r<=tx_len_in_r-packet_len_load;
		packet_len<=packet_len_load+11'd8; // length includes 8-octet UDP header, tx_len does not

	end
end

//tx_req set and clear
always @(posedge clk) begin
	tx_req<=(~tx_req) ? tx_req_in_pipe[0] : ~(tx_ack);
end

// tx_req_pipe
//wire tx_req_flag=tx_req_in|finish send&(|tx_len_in_r);

always @(posedge clk) begin
	tx_req_in_pipe<={tx_req_in_pipe[2:0],tx_req_in_r};
end

assign packet_out=owords[63:56];

assign read_strobe = octet_tx[NUM_BYTE-1] ? ((tx_cnt>16'd5)&(tx_cnt<(packet_len-16'd2))&tx_strobe): 1'b0;
assign data_strobe = rx_data_flag_d ? octet_rx[0]: 1'b0;

assign tx_len = {{(jumbo_dw-11){1'b0}},packet_len};
endmodule
