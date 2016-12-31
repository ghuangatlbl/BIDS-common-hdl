`timescale 1ns / 1ns

module pi_gain2(
	input clk,
	input signed [17:0] in_d,  // Pairs of data points, X and Y
	input in_strobe,  // signals X this clock, followed by Y
	output signed [17:0] out_d,
	output out_strobe,
	input zerome,
	input prop8x,
	input mag_mode,  // X difference restricted to positive values
	input signed [17:0] x_set,
	input signed [17:0] y_set,
	input signed [17:0] x_prop,
	input signed [17:0] y_prop,
	input signed [17:0] x_freq,
	input signed [17:0] y_freq
);

// Universal definition; note: old and new are msb numbers, not bit widths.
`define SAT(x,old,new) ((~|x[old:new] | &x[old:new]) ? x : {x[old],{new{~x[old]}}})

// First pipeline phase: subtract input from setpoint
reg signed [18:0] diff1=0;
reg signed [17:0] prop_coef=0;
reg strobe1=0;
always @(posedge clk) begin
	diff1 <= $signed(in_strobe ? x_set : y_set) - in_d;
	strobe1 <= in_strobe;
end

// Second pipeline phase: clip the difference
// In magnitude mode, restrict difference to be positive.
reg signed [17:0] diff2=0;
reg strobe2=0;
wire signed [17:0] mag_clip = diff1[18] ? 18'b0 : (~|diff1[18:17]) ? diff1 : {1'b0,{17{1'b1}}};
always @(posedge clk) begin
	diff2 <= (strobe1&mag_mode&zerome) ? mag_clip : `SAT(diff1,18,17);
	prop_coef <= strobe1 ? x_prop : y_prop;
	strobe2 <= strobe1;
end

// Third pipeline phase: multiply by proportional gain
reg signed [35:0] prop_full=0;
wire signed [21:0] prop = prop_full[34:13];
reg strobe3=0;
always @(posedge clk) begin
	prop_full <= diff2 * prop_coef;
	strobe3 <= strobe2;
end

// Fourth pipeline phase: clip
reg signed [17:0] prop_clip=0;
reg signed [17:0] int_in_coef=0;
reg strobe4=0;
always @(posedge clk) begin
	if (prop8x)
		prop_clip <= {`SAT(prop,21,14), 3'b0};   // 8x gain range
	else
		prop_clip <= `SAT(prop,21,17);           // default gain range
	int_in_coef <= strobe3 ? x_freq : y_freq;
	strobe4 <= strobe3;
end

// Fifth pipeline phase: multiply by integral coefficient (frequency)
reg signed [35:0] int_in_full=0;
wire signed [21:0] int_in = int_in_full[34:13];
reg strobe5=0;
always @(posedge clk) begin
	int_in_full <= prop_clip * int_in_coef;
	strobe5 <= strobe4;
end

// Sixth pipeline phase: accumulate integral term,
// Seventh pipeline phase: saturate
reg signed [24:0] accum1=0;
reg signed [23:0] accum2=0, accum3=0;
reg strobe6=0, strobe7=0;
always @(posedge clk) begin
	strobe6 <= strobe5;
	strobe7 <= strobe6;
	// Gross stupidity, can almost certainly be improved.
	if (strobe5 | strobe6) accum1 <= accum3 + int_in;
	                       accum2 <= zerome ? 24'b0 :`SAT(accum1,24,23);
	if (strobe5 | strobe6) accum3 <= zerome ? 24'b0 :`SAT(accum1,24,23);
end

// Seventh pipeline phase: combine P and I terms
// Eighth pipeline phase: saturate
reg signed [17:0] prop1=0, prop2=0, prop3=0;  // pipeline balance
reg signed [18:0] sum1=0;
reg signed [17:0] sum2=0;
reg strobe8=0, strobe9=0;
always @(posedge clk) begin
	prop1 <= prop_clip;
	prop2 <= prop1;
	prop3 <= prop2;
	sum1 <= $signed(accum2[23:6]) + prop3;
	sum2 <= `SAT(sum1,18,17);
	strobe8 <= strobe7;
	strobe9 <= strobe8;
end

assign out_d = sum2;
assign out_strobe = strobe9;

endmodule
