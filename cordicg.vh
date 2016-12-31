// machine generated from cordicgx.m
// o=22  s=20
`ifndef CORDIC_COMPUTE
parameter cordic_delay=20;
`else
wire [21:0] x1 = {xt1,{(22-width){1'b0}}};
wire [21:0] y1 = {yt1,{(22-width){1'b0}}};
wire [22:0] z1 = {zt1,{(22-width){1'b0}}};
wire [1:0] op2 ; wire [21:0] x2 , y2 ; wire [22:0] z2 ;  cstageg #(  1, 23, 22, def_op) cs1  (clk, op1 , x1 ,  y1 , z1 , 23'd619011, op2 , x2 ,  y2 ,  z2 );
wire [1:0] op3 ; wire [21:0] x3 , y3 ; wire [22:0] z3 ;  cstageg #(  2, 23, 22, def_op) cs2  (clk, op2 , x2 ,  y2 , z2 , 23'd327068, op3 , x3 ,  y3 ,  z3 );
wire [1:0] op4 ; wire [21:0] x4 , y4 ; wire [22:0] z4 ;  cstageg #(  3, 23, 22, def_op) cs3  (clk, op3 , x3 ,  y3 , z3 , 23'd166025, op4 , x4 ,  y4 ,  z4 );
wire [1:0] op5 ; wire [21:0] x5 , y5 ; wire [22:0] z5 ;  cstageg #(  4, 23, 22, def_op) cs4  (clk, op4 , x4 ,  y4 , z4 , 23'd83335 , op5 , x5 ,  y5 ,  z5 );
wire [1:0] op6 ; wire [21:0] x6 , y6 ; wire [22:0] z6 ;  cstageg #(  5, 23, 22, def_op) cs5  (clk, op5 , x5 ,  y5 , z5 , 23'd41708 , op6 , x6 ,  y6 ,  z6 );
wire [1:0] op7 ; wire [21:0] x7 , y7 ; wire [22:0] z7 ;  cstageg #(  6, 23, 22, def_op) cs6  (clk, op6 , x6 ,  y6 , z6 , 23'd20859 , op7 , x7 ,  y7 ,  z7 );
wire [1:0] op8 ; wire [21:0] x8 , y8 ; wire [22:0] z8 ;  cstageg #(  7, 23, 22, def_op) cs7  (clk, op7 , x7 ,  y7 , z7 , 23'd10430 , op8 , x8 ,  y8 ,  z8 );
wire [1:0] op9 ; wire [21:0] x9 , y9 ; wire [22:0] z9 ;  cstageg #(  8, 23, 22, def_op) cs8  (clk, op8 , x8 ,  y8 , z8 , 23'd5215  , op9 , x9 ,  y9 ,  z9 );
wire [1:0] op10; wire [21:0] x10, y10; wire [22:0] z10;  cstageg #(  9, 23, 22, def_op) cs9  (clk, op9 , x9 ,  y9 , z9 , 23'd2608  , op10, x10,  y10,  z10);
wire [1:0] op11; wire [21:0] x11, y11; wire [22:0] z11;  cstageg #( 10, 23, 22, def_op) cs10 (clk, op10, x10,  y10, z10, 23'd1304  , op11, x11,  y11,  z11);
wire [1:0] op12; wire [21:0] x12, y12; wire [22:0] z12;  cstageg #( 11, 23, 22, def_op) cs11 (clk, op11, x11,  y11, z11, 23'd652   , op12, x12,  y12,  z12);
wire [1:0] op13; wire [21:0] x13, y13; wire [22:0] z13;  cstageg #( 12, 23, 22, def_op) cs12 (clk, op12, x12,  y12, z12, 23'd326   , op13, x13,  y13,  z13);
wire [1:0] op14; wire [21:0] x14, y14; wire [22:0] z14;  cstageg #( 13, 23, 22, def_op) cs13 (clk, op13, x13,  y13, z13, 23'd163   , op14, x14,  y14,  z14);
wire [1:0] op15; wire [21:0] x15, y15; wire [22:0] z15;  cstageg #( 14, 23, 22, def_op) cs14 (clk, op14, x14,  y14, z14, 23'd81    , op15, x15,  y15,  z15);
wire [1:0] op16; wire [21:0] x16, y16; wire [22:0] z16;  cstageg #( 15, 23, 22, def_op) cs15 (clk, op15, x15,  y15, z15, 23'd41    , op16, x16,  y16,  z16);
wire [1:0] op17; wire [21:0] x17, y17; wire [22:0] z17;  cstageg #( 16, 23, 22, def_op) cs16 (clk, op16, x16,  y16, z16, 23'd20    , op17, x17,  y17,  z17);
wire [1:0] op18; wire [21:0] x18, y18; wire [22:0] z18;  cstageg #( 17, 23, 22, def_op) cs17 (clk, op17, x17,  y17, z17, 23'd10    , op18, x18,  y18,  z18);
wire [1:0] op19; wire [21:0] x19, y19; wire [22:0] z19;  cstageg #( 18, 23, 22, def_op) cs18 (clk, op18, x18,  y18, z18, 23'd5     , op19, x19,  y19,  z19);
// round, not truncate
assign xout     = x19[21:22-width] + x19[21-width];
assign yout     = y19[21:22-width] + y19[21-width];
assign phaseout = z19[22:22-width] + z19[21-width];
`endif
