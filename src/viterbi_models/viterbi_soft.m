clear;clc
rng(5);
message_size = 50000;
input = randi([0,1], 1, message_size);
n=2;k=1;L=3;
gen=[5,7];

res = [, ];

%% Generate roll codes
trellis = poly2trellis(L,gen);
code_data = convenc(input,trellis);

%% BPSKModify 
sym_tx = code_data;
sym_tx(sym_tx == 0) = -1;
SNRs_dB = -10:0.25:15;

for SNR_dB = SNRs_dB

    %%  Noise
    snr = 10^(SNR_dB/10);
    sym_rx = awgn(sym_tx, snr, 'measured');
    % plot(sym_rx)
    
    %% BPSKDecompose
    %  Simple quantification, bite width is4
    [~,qcode]=quantiz(-sym_rx,[-0.875 -0.75,-0.625 -0.5,-0.375 -0.25,-0.125 0,0.125 0.25,0.375 0.5,0.625 0.75 0.875],15:-1:0);
    BPSK_REC_Data = (qcode);
    
    tblen=5*(k);
    x=zeros(1,2*tblen);
    BPSK_REC_Data=[BPSK_REC_Data(:,1:end),x];
    
    %%  Viterbi decoding
    d = vitdec(BPSK_REC_Data,trellis,tblen,'term','soft',4);
    Decode_Data = d(1:end-tblen*k);
    %  Calculation error rate
    [~,ber] = biterr(input,Decode_Data);

    res = [res; [SNR_dB, ber]];
    fprintf("BER = %.5f при SNR = %d дБ\n", ber, SNR_dB);
end

figure();  
semilogy(res(:,1), res(:,2));
xlabel('SNR dB');  
ylabel('BER');  
title('BER SOFT');
grid on;
