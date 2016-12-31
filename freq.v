`timescale 1ns / 1ns

module freq(
	input clk,
	input strobe,
	input [1:0] phase,
	output signed [15:0] freq,
	output [15:0] errs
);

parameter ref_len=17;

reg [1:0] old_phase=0, phase_diff=0;
always @(posedge clk) if (strobe) begin
	old_phase <= phase;
	phase_diff <= phase - old_phase;
end

// 17-bit reference counter, in SPX context with strobes
// arriving at 1.63 MHz, and recording quarter-turn events,
// gives a frequency resolution of 3.1 Hz, updated 12 times
// per second.
reg [16:0] ref_cnt=0;
reg signed [16:0] phase_cnt=0, phase_read=0;
reg [16:0] err_cnt=0, err_read=0;
always @(posedge clk) if (strobe) begin
	if (phase_diff != 2'b10) phase_cnt <= phase_cnt + $signed(phase_diff);
	if (phase_diff == 2'b10) err_cnt <= err_cnt+1;
	if (ref_cnt[ref_len-1:0]==0) begin
		phase_read <= phase_cnt;  phase_cnt <= 0;
		err_read <= err_cnt;  err_cnt <= 0;
	end
	ref_cnt <= ref_cnt+1;
end

// Drop one (mostly noise) bit on readout, so 1 bit represents 6.2 Hz
// If error counter is more than a handful, its exact value doesn't matter.
assign freq=phase_read[16:1];
assign errs=err_read[15:0];

endmodule
