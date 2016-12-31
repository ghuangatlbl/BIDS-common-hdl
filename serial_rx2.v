// Synthesizes to 253 slices at 138 MHz in XC3Sxxx-4 using XST-8.2i
`timescale 1ns / 1ns

module serial_rx2(
	input clk,  // timespec 7.2 ns
	// input tick,
	input bit,
	output reg sync,
	output reg [63:0] d,
	output reg [7:0] errors
);

// handles the double-sampled input, automatic search for
// proper receive clock phase, and error counting.

// Multiplex between possible data sources
reg b1=0, b2=0;
always @(posedge clk) begin
	b1 <= bit;
	b2 <= b1;
end

wire sync1, sync2, err1, err2;
wire [63:0] d1, d2;
reg tick=0;
serial_rx rx1(.clk(clk), .tick(tick), .bit(b1), .sync(sync1), .d(d1), .err(err1));
serial_rx rx2(.clk(clk), .tick(tick), .bit(b2), .sync(sync2), .d(d2), .err(err2));

// since we delay data and use the same tick for both Rx units,
// all four potential sync and err signals happen either at the same (tick)
// clock cycle, or separated by one.  Always take action at the time of sync2.
initial begin
	d=0;
	errors=0;
	sync=0;
end
reg syncx=0, err1d=0, err2d=0;
always @(posedge clk) begin
	if (sync1) err1d <= err1;
	if (sync2) err2d <= err2;
	syncx <= sync2;
	if (syncx & ~(err1d & err2d)) d <= err2d ? d1 : d2;
	if (syncx &  (err1d & err2d)) errors <= errors+1;
	sync <= syncx & ~(err1d & err2d);
end

reg syncy=0, syncz=0;
// width of this register sets period of ticks
parameter serial_cnt_width=3;
reg [serial_cnt_width-1:0] tcnt=1;
always @(posedge clk) begin
	// delay tick an extra cycle if err1
	// advance tick by a cycle if err2
	// if both err1 and err2, we have to slew one direction or the
	// other, doesn't matter which as long as it's consistent
	// if both err1 and err2, consider leaving phase alone for
	// one frame, so we don't create future timing errors when there
	// was really a short-duration non-timing error.
	syncy <= syncx;
	syncz <= syncy;
	tcnt <= tcnt + (err1d&syncz ? 2'b00 : (err2d&syncz ? 2'b10 : 2'b01));
	tick <= ~|tcnt;
end

endmodule
