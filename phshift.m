% Generalization of phase shifter (and amplitude setter)
% used in SNS -- converted to far-from-IQ, in fact optimized
% for f=f_S/8.  Close enough to APEX's f=f_S/7 to work well there.
%
% There are equations to set the two multipliers based on desired
% amplitude and phase shift at f=f_S/7.  See phshift_tb.v.
% The host will run those equations to find the register
% values to set in the FPGA.  See
%  http://recycle.lbl.gov/~ldoolitt/llrf/neariq.pdf
%  file://recycle.lbl.gov/llrf/lc/neariq/outer2.pdf
f=[0:.001:0.5]';
z=exp(2*pi*i*f);

figure(1)
for phs=[0:.1:2]*pi
  plot(f,abs(cos(phs)+sin(phs)*z.^(-2)))
  hold on
end
plot(1/7*[1;1],[0;1])
hold off

figure(2)
for phs=[0:.1:2]*pi
  plot(f,arg(cos(phs)+sin(phs)*z.^(-2))*180/pi)
  hold on
end
plot(1/7*[1;1],[-180;180])
hold off
