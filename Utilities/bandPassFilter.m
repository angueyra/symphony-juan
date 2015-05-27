function Xfilt = bandPassFilter(X,Flow,Fhigh,SampleInterval)
L = size(X,2);
if L == 1 %flip if given a column vector
    X=X'; 
    L = size(X,2);
end

FreqStepSize = 1/(SampleInterval * L);
FreqHighPt = round(Fhigh / FreqStepSize);
FreqLowPt = round(Flow / FreqStepSize);

FFTData = fft(X, [], 2);
FFTData(:,FreqLowPt:FreqHighPt) = 0;
FFTData(:,end-FreqHighPt:end-FreqLowPt) = 0;

Xfilt = real(ifft(FFTData, [], 2));

% Wn(1) = low*SampleInterval; %normalized frequency cutoff
% Wn(2) = high*SampleInterval; %normalized frequency cutoff
% [z, p, k] = butter(1,Wn,'stop');
% [sos,g]=zp2sos(z,p,k);
% myfilt=dfilt.df2sos(sos,g);
% Xfilt = filter(myfilt,X');
% Xfilt = Xfilt';	

