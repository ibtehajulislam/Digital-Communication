function [rxsig, tmlt3]=txmlt3(ns,MM);
load cat5dat

false=0; true=1; % define the boolean variables.

% Create the NRZ sequence beginning with the Idle sequence.
tnrz=ones(1,ns);% 

% Scamble the data using the LFSR with X(n)=X(n-11)+X(n-9)
% Create the key stream
key=zeros(1,length(tnrz));
lfsr=[1 0 0 1 1 0 1 1 0 0 1]; % An arbitrary seed value
for n=1:length(tnrz) 
   key(n)=xor(lfsr(9),lfsr(11));
   lfsr=[key(n) lfsr(1:10)];
end
tsnrz=xor(tnrz,key); % Create the scrambled NRZ data.

% Encode the scrambled NRZ data into MLT-3.
P=1; Z=0; M=-1; % define the encoder state machine states.
tmlt3=zeros(1,length(tnrz)); % Create the transmit output vector for MLT3 signaling.
tbs=zeros(1,length(tnrz)); % Create the trans. o/p vector for binary antipodal signaling.
LOF=false; % Initialize the state of the Last Output Flag.
state=Z; % Initialize the encoder state.
for n=1:length(tnrz) %2^11
   if tsnrz(n)==1 tbs(n)=1; else tbs(n)=-1; end % generates a binary sequence
   switch state
      case Z
         switch tsnrz(n)
            case 1
               if LOF==false
                  tmlt3(n)=1; state=P; LOF=true;
               else
                  tmlt3(n)=-1; state=M; LOF=false;
               end
            case 0
               tmlt3(n)=0;
         end % end tsnrz(n) switch
      case P
         switch tsnrz(n)
            case 1
               tmlt3(n)=0; state=Z;
            case 0
               tmlt3(n)=1;
         end % end tsnrz(n) switch
      case M
         switch tsnrz(n)
            case 1
               tmlt3(n)=0; state=Z;
            case 0
               tmlt3(n)=-1;
         end % end tsnrz(n) switch
   end % end state switch
end % end mlt-3 encoding
Rp=mean(abs(tmlt3).^4)/mean(abs(tmlt3).^2);
% Run the mlt-3 transmit waveform through the channel.
% 
% Create a filter to reflect the transformer high frequency cutoff.
[bt,at] = butter(1,150/1000);

% Upsample the mlt-3 coded signal to MM samples per symbol.  Convolve with a rectangular filter
% to approximate the DAC output.  ts=.5ns
txmlt3=[tmlt3; zeros(MM-1,length(tmlt3))];
txmlt3=reshape(txmlt3,1,prod(size(txmlt3))); % Inserts zeros
txbs=[tbs; zeros(MM-1,length(tbs))]; % Upsample the binary signaling case.
txbs=reshape(txbs,1,prod(size(txbs))); % Inserts zeros
ts=(0:1:length(txmlt3)-1)/2000;
brect=ones(1,MM);
tsig=filter(brect,1,txmlt3);
tbsig=filter(brect,1,txbs);
% Filter the transmit signal to yield approximately 4ns rise time.
txsig=filter(bt,at,tsig);
txsig=filter(bt,at,txsig);
txbsig=filter(bt,at,tbsig);
txbsig=filter(bt,at,txbsig);

% Filter the transmit signals with the channel model filter truncated to 256 taps.
% Warning: This can take a long time.
%txsig=[txsig zeros(1,255)];
for n=1:5
   rxsig(n,:)=filter(ht(n,1:256),1,txsig);
end
%rxsig=rxsig(:,256:ns*MM+255);