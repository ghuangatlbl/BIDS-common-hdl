% generate command line flags to set coefficients in Verilog simulation
T=1/100.0;   % time in microseconds
f0=1.00/7/T;     % aliased MHz
w0=f0*2*pi;   % radians/s
z0=exp(j*w0*T);

bandwidth=0.0001; % MHz
beta=bandwidth*2*pi*T;

poly=cdfig(beta,z0);

z0i=1/z0;
peak=(1-z0i)/(polyval(poly,z0i));

c=poly(2);  ic=floor((c-1)*2^17+0.5);  fc=ic*2^(-17)+1;
d=poly(1);  id=floor(d*2^17+0.5);      fd=id*2^(-17);
printf('+cm1=%d +d=%d\n', floor((c-1)*2^17+0.5), floor(d*2^17+0.5));
