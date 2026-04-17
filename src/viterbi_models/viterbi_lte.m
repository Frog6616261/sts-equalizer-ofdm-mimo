
rng(1034);
%result = [SNR, BER];
res = [, ];
message_size = 50000;
SNRs_dB = -10:0.25:15;

for SNR_dB = SNRs_dB
    txBits = randi([0 1], message_size,1);
    codedData = lteConvolutionalEncode(txBits);
    txSym = lteSymbolModulate(codedData,'QPSK');
    
    %% ADD NOIZE
    awgn_channel = comm.AWGNChannel('EbNo', SNR_dB, 'BitsPerSymbol', log2(length(unique(txSym))));
    rxSym = awgn_channel(txSym);
    
    %xylimits = [-2.5 2.5];
    %cdScope = comm.ConstellationDiagram('ReferenceConstellation',txSym,'XLimits',xylimits ,'YLimits',xylimits);
    %cdScope(rxSym)
    
    %% DEMODULATE AND DECODE
    softBits = lteSymbolDemodulate(rxSym,'QPSK','Soft');
    out = lteConvolutionalDecode(softBits);
    errs = sum(out ~= int8(txBits));
    BER = errs/message_size;
    
    res = [res; [SNR_dB, BER]];
    fprintf("BER = %.5f при SNR = %d дБ\n", BER, SNR_dB);
end

figure();  
semilogy(res(:,1), res(:,2));
xlabel('SNR dB');  
ylabel('BER');  
title('BER LTE');
grid on;



