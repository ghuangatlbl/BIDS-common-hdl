`timescale 1ns / 1ns

module circle_buf_tb;

reg wclk;
integer cc, errors;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("circle_buf2.vcd");
		$dumpvars(5,circle_buf_tb);
	end
	errors = 0;
	for (cc=0; cc<6000; cc=cc+1) begin
		wclk=0; #5;
		wclk=1; #5;
	end
	$display("%d errors  %s", errors, errors>0 ? "FAIL" : "PASS");
	$finish();
end

reg rclk=0;
always begin
	rclk=0; #6;
	rclk=1; #6;
end

// Source emulation
reg [15:0] data_w=0;
reg stb_w=0, trig_ext=0;
reg trig_internal = 0;
always @(posedge wclk) begin
	stb_w <= (cc%4)==2;
	trig_ext <= cc==300 || cc==1498 || cc==2200 || cc==400 || cc==433 ||
    cc==564 || cc==584;
    trig_internal <= cc<2000 ? 0 : 1;
	data_w <= cc;
end

// Readout emulation
reg [5:0] read_addr=0;
reg [6:0] read_counter=0, read_cnt=0;
reg stb_r=0, odata_val=0;
reg [1:0] ocnt=0;
wire otrig=(ocnt==3);
wire trig_out, data_gate;
integer frame=0;
always @(posedge rclk) begin
    stb_r <= otrig;
    ocnt <= ocnt+1;
    if (data_gate) begin
	    if (otrig) read_addr <= read_addr+1;
	    if (otrig & (&read_addr)) frame <= frame+1;
        odata_val <= stb_r;
    end
    if (stb_r & data_gate) begin
        if (trig_out) begin
            read_counter <= 0;
        end
        else begin
            read_counter <= read_counter+1;
        end
    end
end

reg reset= 0;
reg [5:0] trigger_location = 32;
// Instantiate Device Under Test
wire [15:0] data_read, buf_stat;
circle_buf2 #(.aw(6)) dut(
    .wclk(wclk), .stb_w(stb_w), .data_w(data_w),
    .data_gate_in(1'b1),
    .trig_ext(trig_ext),
    .trig_internal(trig_internal),
    .trigger_location(trigger_location),
    .reset(reset),
    .rclk(rclk), .data_r(data_read), .stb_r(stb_r), .addr_r(read_addr),
    .trig_out(trig_out),
    .data_gate(data_gate)
);

// Check result
reg [15:0] prev_read=0;
wire [5:0] save_addr=buf_stat[5:0];
wire record_type=buf_stat[15];
reg mismatch=0, fault=0, buffer_mark=0;
always @(posedge rclk) if (odata_val) begin
	prev_read <= data_read;
	mismatch = (data_read != prev_read+4);
	buffer_mark = (save_addr == read_addr) & ~record_type;
	fault = mismatch & ~buffer_mark & (read_addr != 0) & (frame>1);
	if (fault) errors = errors+1;
end

endmodule
