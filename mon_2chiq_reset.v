`timescale 1ns / 1ns

module mon_2chiq_reset #(
	parameter dwi=16,  // data width
	parameter rwi=28,  // result width
	// Difference between above two widths should be N*log2 of the maximum number
	// of samples per CIC sample, where N=2 is the order of the CIC filter.
	parameter davr=3,  // how many guard bits to keep in output of multiplier
	parameter dwlo=18  // Local Oscillator data width
) (
	input clk,  // timespec 8.4 ns
	input signed [dwi-1:0] iqd,  // two-way interleaved data
	input signed [17:0] scale,  // e.g., 18'd61624 = floor((32/33)^2*2^16)
	// Note that scale is typically positive; full-scale negative is not allowed
	input iqs,  // sync high when iq_data holds I, low when iq_data holds Q
	input samp,
	input signed [rwi-1:0] s_in,
	output signed [rwi-1:0] s_out,
	input g_in,
	output g_out,
	input reset
);


// Maybe wasteful, but use a multiplier so we can get full-scale to match between
// input and output when using a non-binary CIC interval
reg signed [18+dwi-1:0] product_iq=0, product_iq2=0;
always @(posedge clk) begin
	product_iq <= iqd * scale;
	product_iq2 <= product_iq;
end
wire signed [dwi+davr-1:0] scaled_iq = product_iq2[18+dwi-2:18-davr-1];

reg [1:0] iq_sync_sr=0;
wire iq_syncx = iq_sync_sr[1];
reg [dwi+davr-1:0] i_data0=0, i_data=0, q_data=0;
always @(posedge clk) begin
	iq_sync_sr <= {iq_sync_sr[0:0],iqs};
	if ( iq_syncx) i_data0 <= scaled_iq;
	if (~iq_syncx) q_data  <= scaled_iq;
	i_data <= i_data0;  // Time-align the common case where I and Q are paired
end

reg [1:0] reset_r=0;
always @(posedge clk) reset_r <= {reset_r[0],reset};

wire signed [rwi-1:0] s_reg1, s_reg2;
wire g_reg1, g_reg2;

wire signed [rwi-1:0] i1out;
double_inte_reset #(.dwi(dwi+davr),.dwo(rwi))          i1(.clk(clk), .in(i_data), .out(i1out), .reset(reset_r[1]));
serialize   #(.dwi(rwi))                         s1(.clk(clk), .samp(samp), .data_in(i1out),
	.stream_in(s_reg2), .stream_out(s_reg1), .gate_in(g_reg2), .gate_out(g_reg1));

wire signed [rwi-1:0] i2out;
double_inte_reset #(.dwi(dwi+davr),.dwo(rwi))          i2(.clk(clk), .in(q_data), .out(i2out), .reset(reset_r[1]));
serialize   #(.dwi(rwi))                         s2(.clk(clk), .samp(samp), .data_in(i2out),
	.stream_in(s_in), .stream_out(s_reg2), .gate_in(g_in), .gate_out(g_reg2));

assign s_out = s_reg1;
assign g_out = g_reg1;

endmodule
