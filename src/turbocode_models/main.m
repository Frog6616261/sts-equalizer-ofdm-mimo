% QPP interliver
% count coders = 2
% type coders = RSC
% constrain length
% memory = 3
% generation polinoms (13, 15) octal
% feedback polynomial 13 octal
% basecoderate 1/3
% maximum block 6144

clear; clc;

modOrd = 16;
bps = log2(modOrd);

L = 512;
trellis = poly2trellis(4, [13 15], 13);
numiter = 6;

n = log2(trellis.numOutputSymbols);
numTails = log2(trellis.numStates) * n;
M = L * (2*n - 1) + 2 * numTails;
rate = L / M;

rng default

QPP_interliver_permut = get_QPP_interleaver_permutation(L);

turboenc = comm.TurboEncoder(trellis, QPP_interliver_permut);
turbodec = comm.TurboDecoder(trellis, QPP_interliver_permut, numiter);

EbNo_dB = 2:0.5:5;
ber = zeros(size(EbNo_dB));

for id = 1:numel(EbNo_dB)
    EsNo_dB = EbNo_dB(id) + 10*log10(bps);
    snr_dB = EsNo_dB + 10*log10(rate); % E_simb_coded/E_simb_decoded = coderate = L/M
    noiseVar = 1 / (10^(snr_dB/10));

    numErr = 0;
    numBits = 0;

    while numErr < 100 && numBits < 1e5
        data = randi([0 1], L, 1);
        encodedData = turboenc(data);

        modSignal = qammod(encodedData, modOrd, ...
            'InputType', 'bit', ...
            'UnitAveragePower', true);

        receivedSignal = awgn(modSignal, snr_dB, 'measured');

        demodSignal = qamdemod(receivedSignal, modOrd, ...
            'OutputType', 'llr', ...
            'UnitAveragePower', true, ...
            'NoiseVariance', noiseVar);

        receivedBits = turbodec(-demodSignal);

        numErr = numErr + sum(data ~= receivedBits);
        numBits = numBits + numel(data);
    end

    ber(id) = numErr / numBits;
end

semilogy(EbNo_dB, ber, 'o-');
grid on;
xlabel('Eb/No (dB)');
ylabel('BER');
title('Turbo code, 16-QAM, AWGN');


