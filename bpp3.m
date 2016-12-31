fb=-1;
cset3   % should set fc and fd
fc
fd

load "bandpass3.dat"

id=bandpass3(:,1);
od=bandpass3(:,2);
npt=length(id);
t=[1:npt]';

f_den = [1 fb fc fd];
f_num = [0 0 0 0 0 0 1 -1]/2;
odc=filter(f_num,f_den, id);
plot(t,id+60000,';input;', t,od/2,';output;');
xlabel('cycle')
% print('bpp.eps','-depsc2','-landscape')

oscale=max(abs(od));
er=od-odc;
pperr=max(abs(er));
rmserr=std(er);
rmserr_end=std(er(400:end));
printf('Peak signal = %.0f   peak error = %.3f   rms error = %.3f (%.3f at end)\n', oscale, pperr, rmserr, rmserr_end)

if (pperr/oscale<0.0002)
  printf("PASS\n");
else
  printf("FAIL\n");
  exit(1);
end
