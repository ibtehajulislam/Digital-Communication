clear
% 1000TXRX.m: a grogram to simulate 1000 Base T Transceiver
% what is missing is the slicer function and the time recovery part
clf
clear

ns=2^15;MM=16;
[rxn, Rp]=txmlt3(ns,MM);
%RX section
rx=rxn(5,:);
phase=-7;
factor=1.9;
rx=factor*rx;
Rp=.5;
mu=[.18 .025];LF=9;LBT=11;
ci=zeros(1,LF+LBT);
ci(floor((LF)/2))=1;


p=length(rx)/MM;      % length of the input signal sequence
  x=0;
  LL=LF+LBT;
  sbi=zeros(1,LBT);
  sw1=zeros(1,LF-1);
  swi=zeros(1,LF);
  cwi=ci(1:LF); % coefficients of the FWD filters
  cbi=ci(LF+1:LL); % coefficients of the FBK filters
  Er=[];
  
sample_time=phase;
SITA=[phase];Sam=[phase];

  for k=1:p;
     ss=rx(MM*(k)+phase);

    swi=[ss sw1];               % signal applied to the FWD filters


    % Perform the filtering operation
    a(k)=cwi*(swi')+cbi*(sbi');

% the signal just before the slicer

    x(k)=slicmlt3(a(k));% slicer operation
    if k>1000;
         er(k)=(x(k)-a(k));%Er=[Er er(:)];
         Dout=x(k);
         y(k)=x(k);
         uq(k)=a(k);
    else
       er(k)=a(k)*(Rp-(abs(a(k)))^2);y(k)=x(k);
       Dout=[0];
uq(k)=a(k);
end

    error=(er(k));%  error
   if k<= 1000,
muu=mu(1); else muu=mu(2);end
    %The CMA
    %++++++++++++
    cwi=cwi+muu.*(error)*(swi);
    cbi=cbi+muu.* (error)*(sbi);

      sw1=[ss sw1(1:LF-2)];
      sbi=[Dout sbi(1:LBT-1)];
      
 %in the following you can perform your Time Recovery when k>=2
    if k>=2;
        sample_time= phase+0.1*((a(k)*x(k-1))-(a(k-1)*x(k)));
        phase=round(sample_time);
    end
    SITA=[SITA phase];Sam=[Sam sample_time];

  end
cw=cwi;cb=cbi;
plot(a,'.')