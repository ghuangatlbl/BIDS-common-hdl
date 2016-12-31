// Phase mean function
// Simple (a+b)/2 gets the high bit wrong.
// The intended typical use case has a approximately equal to b, but that
// could be anyplace around the circle, including on opposite sides of the
// pi/-pi boundary.  This code picks the average point that is inside the
// acute angle between a and b.
module ph_mean(a, b, o, warn);
parameter w=16;
input signed [w-1:0] a, b;
output signed [w-1:0] o;
output warn;
wire signed [w-1:0] d = b - a;
// don't trust synthesizer to handle d/2
assign o = a + $signed({d[w-1],d[w-1:1]});
assign warn = d[w-1] ^ d[w-2];
endmodule
