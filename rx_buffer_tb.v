`timescale 1ns / 1ns

// Very crude representation of the transaction between
// a CY7C68018A (as programmed with xguff) and the LLRF4 FPGA.
// If this fails, the circuit will probably also fail.
// The converse is less likely to hold.
module rx_buffer_tb;

reg usbclk;
integer cc, errors;
reg [15:0] current=0;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("rx_buffer.vcd");
		$dumpvars(5,rx_buffer_tb);
	end
	errors = 0;
	for (cc=0; cc<10000; cc=cc+1) begin
		usbclk=0; #10;
		usbclk=1; #10;
	end
	$display("%d words handled (want 2048), %d errors  %s",
		current, errors, (errors>0 || current!=2048) ? "FAIL" : "PASS");
	$finish();
end

// Source emulation
reg [15:0] src=0;
reg reset_rx=1, ssb=0;
always @(posedge usbclk) begin
	reset_rx <= cc<20;
	ssb <= (cc>50) & ((cc%4)==2);
	// src <= cc;
	if (ssb) src <= src+1;
end

// Readout emulation
reg [8:0] read_cnt=0;
reg ctl1=0;
wire usb_rdy1;
always @(posedge usbclk) begin
	if (usb_rdy1) begin
		ctl1 <= 1;
		read_cnt <= 0;
	end
	if (ctl1) read_cnt <= read_cnt+1;
	if (read_cnt==256) ctl1 <= 0;
end

// Instantiate Device Under Test
// Directly parallels llrf4_apex.v
wire [15:0] usb_data;
wire [15:0] rx_debug;
wire rx_overrun;   // XXX hook me up
wire clr_status=0;    // XXX hook me up
rx_buffer dut(.rst(~reset_rx),
	.usbclk(usbclk), .usbdata(usb_data),
	.RD(ctl1), .have_pkt_rdy(usb_rdy1),
	.rx_overrun(rx_overrun), .clear_status(clr_status),
	.rxclk(usbclk), .rxstrobe(ssb), .rxdata(src),
	.debugbus(rx_debug)
);

// Check result
wire in_packet = usb_rdy1 | (ctl1 & (read_cnt<255));
reg fault;
always @(posedge usbclk) begin
	if (in_packet) begin
		fault = (current != usb_data);
		if (fault) errors=errors+1;
		if (fault) $display("%x %x", usb_data, current);
		current <= current+1;
	end
end

endmodule
