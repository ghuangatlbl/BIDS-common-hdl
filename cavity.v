`timescale 1ns / 1ns

module cavity(
	input clk,
	input signed [15:0] drive,
	output signed [15:0] cav
);

// Goal is a 10 kHz bandwidth cavity, centered at 2/11 of f_clk.
// Thus time constant is 6e-4 of a clock period.
// s-plane pole at f_clk*(2/11*2*pi*i-6e-4) converts to a z-plane pole
// at 0.41517 + 0.90909i.
// Pole pair 1/(z-zp)/(z-zp*) turns into 1/(z^2-z*(z+zp*)+zp*zp*)
// Also known as y*z = drive + y*2*Re(zp) - y*z^(-1)*abs(zp)

// Simple exercise:
//  x=[1;zeros(100,1)];
//  zp=exp(2/11*2*pi*i-6e-3);
//  plot(filter(1,[1 -2*real(zp) abs(zp)],x))

// zp=exp(2/11*2*pi*i-6e-3)   lower the Q for testing
parameter zp_real = 0.412929985;
parameter zp_mag  = 0.994017964;
reg signed [15:0] cav_r=0;
real state_next, state0=0, state1=0;
always @(posedge clk) begin
	state_next = drive*(1-zp_mag) + 2*zp_real*state0 - zp_mag*state1;
	if (state_next >  32767) state_next =  32767;
	if (state_next < -32767) state_next = -32767;
	state1 = state0;
	state0 = state_next;
	cav_r <= state_next;
end

// I've seen a total of about 1 us skew between drive and response
// on the waveform monitor on the hardware.  Start small.
reg_delay #(.dw(16), .len(86)) delay1(.clk(clk), .gate(1'b1),
	.din(cav_r), .dout(cav));

endmodule

