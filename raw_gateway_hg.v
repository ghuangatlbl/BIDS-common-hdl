`timescale 1ns / 1ns

module raw_gateway( clk,
rx_ready, rx_gate, rx_crc, rx_byte,
tx_ack, tx_gate, tx_req, tx_len, tx_byte,
tx_data_gate,tx_data
,rx_data,rx_data_gate);
//data_rx_strobe, data_rx,data_to_net, data_to_net_gate);
parameter NUM_BYTE=8; // NUM_BYTE must in { 1, 2, 4, 8, 16}
parameter MAX_ONE_TXLEN=1024;
localparam TXLEN_WIDTH=$clog2(MAX_ONE_TXLEN)+1;
localparam DWIDTH=NUM_BYTE*8;

input clk;

input rx_ready;
input rx_gate;
input rx_crc; // ignored as in ipv4
input [7:0] rx_byte;

input tx_ack;
input tx_gate;
output tx_req;
output [TXLEN_WIDTH-1:0] tx_len;
output [7:0] tx_byte;

output tx_data_gate;
input [DWIDTH-1:0] tx_data;

output [DWIDTH-1:0] rx_data;
output rx_data_gate;
reg [DWIDTH-1:0] iwords=0;
reg [NUM_BYTE-1:0] octet_rx=0;
// RX
always @(posedge clk) begin
	if (rx_ready) begin
		octet_rx<= 1;
	end
	else if (rx_gate) begin
		octet_rx<={octet_rx[NUM_BYTE-2:0],octet_rx[NUM_BYTE-1]};
		iwords <= {iwords[NUM_BYTE*8-9:0],rx_byte};
	end
end
reg [DWIDTH-1:0] owords=0;
reg [NUM_BYTE-1:0] octet_tx=0;
// TX
reg tx_ack_d=0;
always @(posedge clk) begin
	tx_ack_d <= tx_ack;
	if (tx_ack & ~tx_ack_d) begin
		octet_tx <= 1;
		owords <= tx_data;
	end
	else if (tx_gate) begin
		octet_tx <= {octet_tx[NUM_BYTE-2:0],octet_tx[NUM_BYTE-1]};
		owords <= {owords[NUM_BYTE*8-9:0],8'b0};
	end
end
assign tx_byte=owords[DWIDTH-1:DWIDTH-8];
endmodule
//parameter jumbo_dw=14;
