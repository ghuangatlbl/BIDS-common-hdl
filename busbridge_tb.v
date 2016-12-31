`timescale 1ns / 1ns

module busbridge_tb;

reg clk;
reg fail=0;
integer cc, nrun;
reg trace_writes=0;
reg signed [15:0] adc;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("busbridge.vcd");
		$dumpvars(5,busbridge_tb);
	end
	for (cc=0; cc<70; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
	if (f_cnt != 2) fail=1;
	if (w_cnt != 9) fail=1;
	if (~fail) $display("PASS");
end

reg        bn_write=0;
reg        bn_addr=0;
reg [31:0] bn_data=0;

always @(posedge clk) case(cc)
	10: begin bn_addr <= 0; bn_data <= 32'h00030010; bn_write <= 1; end
	15: begin bn_addr <= 1; bn_data <= 32'h11111111; bn_write <= 1; end
	20: begin bn_addr <= 1; bn_data <= 32'h22222222; bn_write <= 1; end
	25: begin bn_addr <= 1; bn_data <= 32'h33333333; bn_write <= 1; end
	30: begin bn_addr <= 1; bn_data <= 32'h44444444; bn_write <= 1; end // rejected
	40: begin bn_addr <= 0; bn_data <= 32'h10030020; bn_write <= 1; end
	41: begin bn_addr <= 0; bn_data <= 32'h10030020; bn_write <= 1; end // error
	45: begin bn_addr <= 1; bn_data <= 32'h22221111; bn_write <= 1; end
	50: begin bn_addr <= 1; bn_data <= 32'h44443333; bn_write <= 1; end
	55: begin bn_addr <= 1; bn_data <= 32'h66665555; bn_write <= 1; end
	default: begin bn_addr <= 1'bx; bn_data <= 32'bx; bn_write <= 0; end
endcase

wire        bw_write;
wire [15:0] bw_addr;
wire [31:0] bw_data;

wire fault, complete;
busbridge mut(.clk(clk),
	.bn_data(bn_data), .bn_addr(bn_addr), .bn_write(bn_write),
	.bw_data(bw_data), .bw_addr(bw_addr), .bw_write(bw_write),
	.fault(fault), .complete(complete));

integer f_cnt=0, w_cnt=0;
reg [31:0] want, check_data;
always @(posedge clk) begin
	if (fault) f_cnt <= f_cnt+1;
	if (bw_write) w_cnt <= w_cnt+1;
	if ((cc==35 || cc==60) && !complete) fail=1;
	case (bw_addr)
	 16: want=32'h11111111;
	 17: want=32'h22222222;
	 18: want=32'h33333333;
	 32: want=16'h1111;
	 33: want=16'h2222;
	 34: want=16'h3333;
	 35: want=16'h4444;
	 36: want=16'h5555;
	 37: want=16'h6666;
	 default: want=32'hdeadbeef;
	endcase
	check_data = bw_data;
	if (bw_addr >= 32) check_data = check_data & 32'hffff;
	if (bw_write && (check_data!=want)) fail=1;
end

endmodule
