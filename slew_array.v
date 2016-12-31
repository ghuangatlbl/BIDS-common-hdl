`timescale 1ns / 1ns

module slew_array(clk, h_write, h_addr, h_data, enable, wrap, trig, outv);

parameter dw=18;
parameter aw=3;
input clk;  // timespec 7.8 ns
input h_write;
input [aw-1:0] h_addr;
input signed [dw-1:0] h_data;
input enable;  // when zero, values propagate directly to output
input wrap;  // set to allow wrapping, as when value represents phase
input trig;  // start the flow of 2^aw results
output signed [dw-1:0] outv;

reg [aw-1:0] count=0, count1=0, count2=0, count3=0;
reg run=0, run1=0, run2=0, run3=0;
always @(posedge clk) begin
	count <= count+(trig|run);
	count1 <= count;
	count2 <= count1;
	count3 <= count2;
	run <= trig | (run & ~(&count));
	run1 <= run | trig;
	run2 <= run1;
	run3 <= run2;
end

wire signed [dw-1:0] goal, oldv, nextv;
dpram #(.dw(dw), .aw(aw)) hbuf(.clka(clk), .clkb(clk),
	.addra(h_addr), .dina(h_data), .wena(h_write),
	.addrb(count), .doutb(goal));

dpram #(.dw(dw), .aw(aw)) state(.clka(clk), .clkb(clk),
	.addra(count3), .dina(nextv), .wena(run3),
	.addrb(count), .doutb(oldv));

reg signed [dw-1:0] goal1=0, goal2=0, oldv1=0, oldv2=0;
reg signed [dw:0] diff=0;
reg match=0, dir=0;
assign nextv = enable ? (match ? oldv2 : dir ? oldv2-1 : oldv2+1) : goal2;
always @(posedge clk) begin
	// stage 1
	diff <= goal - oldv;
	goal1 <= goal;
	oldv1 <= oldv;
	// stage 2
	match <= diff==0;
	dir <= wrap ? diff[dw-1] : diff[dw];
	oldv2 <= oldv1;
	goal2 <= goal1;
end

assign outv = oldv;

endmodule
