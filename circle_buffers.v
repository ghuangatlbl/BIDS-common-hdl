`timescale 1ns / 1ns
module circle_buffers#(parameter CHANS=7,parameter DWIDTH=16,parameter AWIDTH=14,parameter WID_CHANS=clog2(CHANS),parameter BUF_AW=13)(
	input dsp_clk,

	input signed [DWIDTH*CHANS-1:0] wave,
	input [CHANS-1:0] wave_strobe,
	output [DWIDTH*CHANS-1:0] wave_result,
	output [CHANS-1:0] wave_addr_err,
	output [CHANS-1:0] wave_available,
	input [CHANS-1:0] trig_ext,
	input [CHANS-1:0] reset,

	input rclk,
	//input [LB_AWIDTH-1:0] stream_addr,
	input [CHANS-1:0] stb_r,
	input [CHANS-1:0] rewind
	//input stream_gate

);
function integer clog2;
	input integer value;
	begin
	value = value-1;
	for (clog2=0; value>0; clog2=clog2+1)
		value = value>>1;
end
endfunction

// All the APEX DSP that fits in a single clock domain
//wire [CHANS-1:0] wave_buf_sel;
wire [BUF_AW*CHANS-1:0] wave_r_addr;
genvar ix;
generate for (ix=0; ix<CHANS; ix=ix+1) begin: waveforms
//assign wave_buf_sel[ix] = stream_gate & stream_addr[WID_CHANS-1:0]==ix;
circle_buf4 #(.aw(BUF_AW),.dw(DWIDTH)) wave_buf(.wclk(dsp_clk), .data_w(wave[DWIDTH*(ix+1)-1:(DWIDTH*(ix))]), .data_gate_in(1'b0),
    .trig_ext(trig_ext[ix]), .trig_internal_ena(1'b0), .trigger_location({BUF_AW{{1'b0}}}), .full_flag(),
    .rclk(rclk),.stb_r(stb_r[ix]), .addr_r({BUF_AW{{1'b0}}}), .data_r(wave_result[DWIDTH*(ix+1)-1:DWIDTH*ix]), .data_gate_out(), .empty_flag(),
    .reset(reset[ix]), .stb_w(wave_strobe[ix]), .trig_out(), .buf_count(), .buf_stat(), .triggerable_flag(),
    .r_bank_available(wave_available[ix]),.r_addr(wave_r_addr[BUF_AW*(ix+1)-1:BUF_AW*ix]),.rewind(rewind[ix])
);
assign wave_addr_err[ix]=0;//~(wave_r_addr[ix]==stream_addr[10:4]);

end
endgenerate

endmodule
