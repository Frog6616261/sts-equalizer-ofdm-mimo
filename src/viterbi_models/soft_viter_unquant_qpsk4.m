clear;clc
% Parameters
msgLen = 12000;
M = 4;
% Number of bits per iteration
bitsPerIter = 1.2e4;
% Maximum number of iterations
maxNumIters = 100;
% Maximum number of bit errors to collect
maxNumErrs  = 300;
res = [,];
codeRate = 1/2;
SNRs_dB = 1.5:0.5:7.5; % in dB
trellis = poly2trellis(7, [171 133]); % Standard rate 1/2 convolutional code
enc = comm.ConvolutionalEncoder(trellis);
LLR_runs = length(SNRs_dB);
ber_HD = zeros(3,length(SNRs_dB));
ber_UNQUANTIZED = zeros(3,LLR_runs);
ber_SD = zeros(3,LLR_runs); 
adjSNR = convertSNR( ...
    SNRs_dB,"ebno", ...
    "BitsPerSymbol",log2(M), ...
    "CodingRate",codeRate);

vitDecUNQUANT = comm.ViterbiDecoder(trellis, ...
    'InputFormat','Unquantized', ...
    'TracebackDepth', 32); 
vitDecSD = comm.ViterbiDecoder(trellis, ...
    'InputFormat','Soft', ...
    'SoftInputWordLength',3, ...
    'TracebackDepth',32); 


errorCalcUNQUANT = comm.ErrorRate("ReceiveDelay",32);
errorCalcSD = comm.ErrorRate("ReceiveDelay",32);
%%Plot

fig = figure;
grid on;
ax = fig.CurrentAxes;
hold(ax,'on');
ax.YScale = 'log';
xlim(ax, [SNRs_dB(1)-1, SNRs_dB(end)+1]); ylim(ax, [1e-6 1]);
xlabel(ax,'Eb/No (dB)'); ylabel(ax, 'BER');
title(ax,'LLR vs. Hard Decision Demodulation');
fig.NumberTitle = 'off';
set(fig,'DefaultLegendAutoUpdate','off');

%%algorithm
for idx = 1:LLR_runs
    reset(errorCalcUNQUANT)
    reset(errorCalcSD)
    reset(enc)
    reset(vitDecUNQUANT)
    reset(vitDecSD)

    iter=1;
     while (ber_UNQUANTIZED(2,idx) < maxNumErrs) && (iter <= maxNumIters)
         data = randi([0 1], bitsPerIter, 1); % Generate message bits  
        encData = enc(data);
        modData = pskmod(encData,M, pi/4, ...
            InputType="bit");                % Modulate encoded data
        [chOut,nVar] = awgn(modData,adjSNR(idx)); % Pass modulated signal

        demodDataLLR = pskdemod(chOut,M, pi/4, ...
            OutputType="llr"); % 'LLR' demod

        decDataUNQUANT = vitDecUNQUANT(demodDataLLR);
        ber_UNQUANTIZED(:,idx) = errorCalcUNQUANT(data,decDataUNQUANT);

        quantizedValue = quantiz(-demodDataLLR, ...
            (-3:.1:3)/nVar);
       
        decDataSD = vitDecSD(double(quantizedValue));
        ber_SD(:,idx) = errorCalcSD(data,decDataSD);

        iter = iter+1;
     end
     semilogy(ax, ...
             SNRs_dB(1:LLR_runs), ber_UNQUANTIZED(1,1:LLR_runs));
    legend('LLR with unquantized decoding: Simulation',...
           'Location', 'SouthWest');
    drawnow;

end

