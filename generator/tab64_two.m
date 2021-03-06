function retval = tab64_two(name,n1,n2,den,toff,width,scale)
f = fopen(sprintf('%s.v',name),'wb');
fprintf(f,'// Machine generated by tab64_two.m\n');
fprintf(f,'//  tab64_two(%s,%d,%d,%d,%g)\n',name,n1,n2,den,toff);
fprintf(f,'`timescale 1ns / 1ns\n\n');
fprintf(f,'module %s(\n\tinput [5:0] a,\n',name);
fprintf(f,'\toutput reg signed [%d:0] d1,\n',width-1);
fprintf(f,'\toutput reg signed [%d:0] d2\n);\n\n',width-1);
fprintf(f,'always @(*) case (a)\n');
amp = (2^(width-1)-1)*scale;
for ix=[0:63]
	jx=ix+toff;
	fprintf(f,'\t6%cd%2d: begin d1 = %8d; d2 = %8d; end\n', 39, ix,
	floor(amp*cos(jx*2*pi*n1/den)*cos(jx*2*pi*n2/den)+.5),
	floor(amp*cos(jx*2*pi*n1/den)*sin(jx*2*pi*n2/den)+.5));
end
fprintf(f,'endcase\n\n');
fprintf(f,'endmodule\n');
fclose(f);
