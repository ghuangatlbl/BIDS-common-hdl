`timescale 1ns / 1ns

module circle_buf4_tb;

parameter aw=6;// Address width for the buffer

/************************************************************\
						Clock Generation
	Generate write and read clocks.
	1. Faster wclk
	2. Faster rclk
	3. Equal speed
\************************************************************/

integer cc, errors;
reg slow_clk=0;
reg fast_clk=0;

// Simulation time control part
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("circle_buf4.vcd");
		$dumpvars(0,circle_buf4_tb);
	end
	errors = 0;
	for (cc=0; cc<33000; cc=cc+1) begin
		#10;
	end
	$display("%d errors  %s", errors, errors>0 ? "FAIL" : "PASS");
	$finish();
end

// slow_clk and fast_clk generation
always begin
	slow_clk=0; #50;
	slow_clk=1; #50;
end
always begin
	fast_clk=0; #5;
	fast_clk=1; #5;
end

// In order to test different speed clock for reading writing
// Use status to indicate which clock is faster
parameter FAST_WCLK=0, // Write clock faster, internal trigger
	FAST_RCLK=1, // Read clock faster, internal trigger
	SAME_CLK=2,// wclk rclk same rate, internal trigger
//PRE short for PREPARATION
	EXT_TRIG_PRE0=3, // trigger external, write to full, without reading
	EXT_TRIG_PRE1=4, // trigger external, read to empty, without writing
	EXT_TRIG_SLOW=5,// trigger external, slow trigger test trigger_location
	EXT_TRIG_FAST=6,// trigger external, fast trigger test trigger_location
	RANDOM_TRIG=7;// trigger external, several random trigger_location
//wire [2:0] status=(cc<3000) ? FAST_WCLK : ((cc<6000) ? FAST_RCLK : SAME_CLK);

reg [2:0] status=0;

// Condition generation: different clk rate and different trig source
always @(cc) begin
	if (cc<3000)
		status=FAST_WCLK;
	else if (cc<6000)
		status=FAST_RCLK;
//status=SAME_CLK;
	else if (cc<9000)
		status=EXT_TRIG_PRE0;
	else if (cc<12000)
		status=EXT_TRIG_PRE1;
	else if (cc<15000)
		status=EXT_TRIG_SLOW;
	else if (cc<18000)
		status=EXT_TRIG_PRE0;
	else if (cc<21000)
		status=EXT_TRIG_PRE1;
	else if (cc<24000)
		status=EXT_TRIG_FAST;
	else if (cc<27000)
		status=EXT_TRIG_PRE0;
	else if (cc<30000)
		status=EXT_TRIG_PRE1;
	else if (cc<33000)
		status=RANDOM_TRIG;
end

reg rclk=0;
reg wclk=0;
reg trig_internal_ena=1;
reg trig_ext=0;

// clock generation according to the status
always @(slow_clk or fast_clk or status) begin
	case(status)
		FAST_WCLK: begin wclk=fast_clk; rclk=slow_clk; trig_internal_ena=1; end
		FAST_RCLK: begin wclk=slow_clk; rclk=fast_clk; trig_internal_ena=1; end
		SAME_CLK:  begin wclk=fast_clk; rclk=fast_clk; trig_internal_ena=1; end
		EXT_TRIG_PRE0:  begin wclk=fast_clk; rclk=0; trig_internal_ena=0; end
		EXT_TRIG_PRE1:  begin wclk=0; rclk=fast_clk; trig_internal_ena=0; end
		EXT_TRIG_SLOW:  begin wclk=fast_clk; rclk=fast_clk; trig_internal_ena=0; end
		EXT_TRIG_FAST:  begin wclk=fast_clk; rclk=fast_clk; trig_internal_ena=0; end
		RANDOM_TRIG:  begin wclk=fast_clk; rclk=fast_clk; trig_internal_ena=0; end
		default:   begin wclk=0; rclk=0; end
	endcase
end
/************************************************************\
					Trigger Generation
\************************************************************/
reg [aw+1:0] tg_cnt=0;// trigger generation count
reg random_trig=0;

//tg_cnt is a counter
always @(posedge wclk) begin
	if (tg_cnt==(('b1<<aw+2)-13)) begin
		tg_cnt<=0;
	end else
		tg_cnt<=tg_cnt+1;
end

// random trig generation start from cc=30000
always @(posedge wclk) begin
	case(cc)
		30010: random_trig=1;
		30050: random_trig=1;
		30111: random_trig=1;
		30410: random_trig=1;
		30716: random_trig=1;
		31312: random_trig=1;
		31317: random_trig=1;
		32318: random_trig=1;
		32328: random_trig=1;
		default: random_trig=0;
	endcase
end

//slow and fast trigger generation
always @(tg_cnt or status) begin
	case(status)
		EXT_TRIG_SLOW: begin if(tg_cnt==0) trig_ext=1; else trig_ext=0; end
		EXT_TRIG_FAST: begin trig_ext=tg_cnt[aw-2]; end
		RANDOM_TRIG: trig_ext=random_trig;
		default: trig_ext=0;
	endcase
end

/************************************************************\
					Set Trigger Location
\************************************************************/
reg [aw-1:0] trigger_location=0;

always @(status) begin
	case(status)
//EXT_TRIG_SLOW: begin trigger_location=42; end
//EXT_TRIG_FAST: begin trigger_location=13; end
//RANDOM_TRIG: begin trigger_location=57; end
		default: trigger_location=0;
	endcase
end

/************************************************************\
						Buffer Reset
\************************************************************/
reg reset=0;
initial begin
	reset=1; #254;// In this test bench we must clear reset
// after a negedge and before the next posedge
// of wclk. Please keep this in mind.
// Because the data_w will change on the negedge,
// if we do not obey the rule the first data
// for written is 0x0001 not 0x0000
	reset=0;
end

/************************************************************\
				Write Side, Data Generation
	Usage:

	Input:
	On the wrtie side, we need to provide the data_w, w_clk and
	data_gate_in.
 ------------------------------------------------------------
	data_w: It is the data to be written into the buffer
	w_clk: write clock. The data will be locked into buffer on
		   the posedge of wclk, when the buffer isn't full and
		   data_gate_in is set
	data_gate_in: tell the buffer the data is valid
 ------------------------------------------------------------
	Output:
	full_flag: When set, buffer is full can't eat any data

\************************************************************/

// Data to be written. Source emulation
reg [15:0] data_w=0;// data for write
wire full_flag;// buffer full flag connected to buffer
//wire data_gate_in;
wire stb_w;
//assign data_gate_in=(~full_flag)&&(~reset);

//assign stb_w=(~full_flag)&&(~reset);
reg [4:0] w_cnt=0;
assign stb_w=(w_cnt%5)==0;
always @(posedge wclk) begin
	w_cnt <= w_cnt +1;
end

// I prefer to add present the data on the negedge of wclk
always @(posedge  wclk or posedge reset) begin
	if (reset)
		data_w<=0;
	else if (~full_flag&stb_w)
		data_w<=data_w+1;
end
// first test circle_buf4 with trigger internal

/************************************************************\
				Read Side, Record the data
	Usage:

	Input:
	rclk: Read clock. Data will be given at posedge of rclk
		  When stb_r set
	stb_r: strobe signal for read

	Output:
	data_r: The data We get
	data_gate_out: Inidcates the data is valid or not
	empty_flag: Indicates nothing for read

\************************************************************/
wire [15:0] data_r;
wire data_gate_out;
wire empty_flag;// buffer empty flag connected to buffer
wire stb_r=1'b1;//~empty_flag;

circle_buf4 #(.aw(aw)) dut(.wclk(wclk),.data_w(data_w),.data_gate_in(1'b1), .stb_w(stb_w),
	.trig_ext(trig_ext), .trig_internal_ena(trig_internal_ena),
	.trigger_location(trigger_location), .full_flag(full_flag), .rclk(rclk),
	.stb_r(stb_r), .addr_r({aw{1'bx}}), .data_r(data_r), .data_gate_out(data_gate_out),
	.empty_flag(empty_flag), .reset(reset),.rewind(1'b0));

/************************************************************\
						Error check
	Internal trigger mode:
	The input data is start from 0x0000, each data is previous
	data added by one. So the error check is that the read data
	is start from 0x0000 and increased one by one.

	External trigger:
	Save the first data written into buffer each writing cycle with
	'data_read_check[dut.w_bank]', and then read the data check if
	the data start from  the data saved.
\************************************************************/
// FAST_WCLK FAST_RCLK EXT_TRIG_PRE0 EXT_TRIG_PRE1 EXT_TRIG_SLOW EXT_TRIG_FAST
reg [15:0] data_read_prediction=0;
reg [15:0] data_read_check[1:0];// Record the first written data
reg r_bank=0;
reg w_bank=0;
wire [15:0] temp0;
wire [15:0] temp1;
assign temp0=data_read_check[0];
assign temp1=data_read_check[1];

reg triggered_d=0;
always @(posedge wclk) begin
	triggered_d<=dut.triggered;
end
// recrod the first written data  for each bank
/*always @(posedge wclk) begin
	if ((status==EXT_TRIG_SLOW)||(status==EXT_TRIG_FAST)||(status==RANDOM_TRIG)) begin
		if (dut.triggered&&(!triggered_d)) begin
			if(dut.w_addr>(dut.w_bank ? dut.addr_start1 : dut.addr_start0))
				data_read_check[dut.w_bank]<=data_w-trigger_location-dut.w_addr
							+ (dut.w_bank ? dut.addr_start1 : dut.addr_start0);
			else
				data_read_check[dut.w_bank]<=data_w-trigger_location-dut.w_addr
			-{1'b1,{aw{1'b0}}}+ (dut.w_bank ? dut.addr_start1 : dut.addr_start0);
//+dut.addr_start[dut.w_bank];
		end
	end
end*/
always @(posedge wclk) begin
	if ((status==EXT_TRIG_SLOW)||(status==EXT_TRIG_FAST)||(status==RANDOM_TRIG)) begin
		if(dut.trig_ena)
			data_read_check[dut.w_bank]<=data_w-trigger_location;
	end
end

// dut.r_bank delay one cycle
always @(posedge rclk) begin
	r_bank<=dut.r_bank;
end

// dut.w_bank delay one cycle
always @(posedge wclk) begin
	w_bank<=dut.w_bank;
end

always @(posedge rclk) begin
// trigger internal check
	if ((status==FAST_WCLK)||(status==FAST_RCLK)) begin
		if (data_gate_out) begin
			data_read_prediction<=data_read_prediction+1;
			if (data_r!=data_read_prediction)
				errors<=errors+1;
		end
	end
// trigger external check
	if ((status==EXT_TRIG_SLOW)||(status==EXT_TRIG_FAST)||(status==RANDOM_TRIG)) begin
		if (data_gate_out) begin
			if (r_bank~^dut.r_bank)
				data_read_check[r_bank]<=data_read_check[r_bank]+1;
			if (data_r!=data_read_check[r_bank]) begin
				errors<=errors+1;
			end
		end
	end
end

endmodule
