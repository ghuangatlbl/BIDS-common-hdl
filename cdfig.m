function poly=cdfig(beta,z0)
% approximate a traditional lumped element bandpass filter
% with a cubic IIR digital filter

% See filtfit.tex for derivation, then in maxima:
%  display2d:false;
%  f(z):=(a+b*z^(-1)+c*z^(-2)+d*z^(-3))/(1-z^(-1));
%  g(z):=ratsimp(f(z)/(diff(f(z),z)*z));
%  collectterms(expand(denom(g(z0))*beta-num(g(z0))),a,b,c,d)=0;
% where
%  beta=w0*T/(2*Q)
%  z0=exp(j*w0*T)
%  Y=1/(f(z0)*Q)
% final answer
%  a*(z0^4+beta*z0^3-z0^3)+b*(beta*z0^3+z0^3-z0^2)
%  +c*(2*beta*z0^2+z0^2-beta*z0-z0)+d*(3*beta*z0+z0-2*beta-1)

%b=-2*cos(w0*T);
b=-1;         % hard-coded approximation to -2*cos(w0*T);

% The following four lines are cut-and-pasted from the Maxima output
% shown above:
ka=z0^4+beta*z0^3-z0^3;
kb=beta*z0^3+z0^3-z0^2;
kc=2*beta*z0^2+z0^2-beta*z0-z0;
kd=3*beta*z0+z0-2*beta-1;
rhsz=-(ka*1+kb*b);

%  solve for both real and imaginary components solving
%   ccoz*c + dcoz*d = rhsz
% in real space, this is a 2x2 matrix equation
%   A*y=B
A=[real(kc) real(kd); imag(kc) imag(kd)];
B=[real(rhsz); imag(rhsz)];

CD=A\B;
poly=[fliplr(CD') b 1];
