clear all; close all; clc
%pkg load communications

%% parameters
rng(5); % random seed setter (for repeating the same results)

% viterbi params
n=2;k=1;L=7;
gen=[171 133];
trellis = poly2trellis(L,gen);
tblen=35;
tdhui = 'term';
opmode ='soft';


M = 16; % e.g. 2, 4, 8 -> PSK; 16, 64... -> QAM
numb_messages = 2000;
Nt = 2; Nr = 2;
STEPS = 0:6;
STEP = 2;
START_SNR = -1;

result_names = ["BER ML 1", "BER STS wQR", "BER STS"];
result_names = ["BER STS algo", "BER STS"];
result_names = ["BER STS"];


Ber_STS_wQR = [];
Ber_STS_algo = [];
Ber_STS = [];


for SNR_dBs = STEPS

SNR_dB = START_SNR + SNR_dBs*STEP;

%% Generate Messsage and References simbols
enc = comm.ConvolutionalEncoder(trellis);
[bits_out, numb_bits] = Generate_messages_bits(Nt, numb_messages, M);
cod_vect = enc(bits_out(:));
mod_vect = qammod(cod_vect(:), M, InputType="bit");
Mod_symbols = reshape(mod_vect, Nt, []);


%% Channel fading and Antennas interfernce
h = Generate_random_channel_matrix(Nt,Nr);
%h = [-2, 0.00001+1i ; -0.00001, 1];
%h = [-2, 0.00001+1i, 1; -0.00001, 1, 0.001 + 0.01i; 0, 1 + 2i, 0.001 + 1i];
H = h; % find by pilots symbols
info_symbols_antenna_interference = h*Mod_symbols;


%% Add the AWGN (block "AWGN")
[info_symbols_out_channel, nVar] = ADD_AWGN_MIMO(info_symbols_antenna_interference, SNR_dB);


%% Solve LLR
tic;
%[LLR_STS_algo] = Solve_LLR_STS_algo(info_symbols_out_channel, M, H, nVar);
disp("STS_algo: " + string(toc) + " Snr: " + string(SNR_dB));

tic;
% profile on;
[LLR_STS] = Solve_LLR_STS(info_symbols_out_channel, M, H, nVar, @qammod);
% profile off
% p = profile('info');
% profile viewer;
disp("STS: " + string(toc) + " Snr: " + string(SNR_dB));


%% Viterbi-Decode message
vitDecUNQUANT = comm.ViterbiDecoder(trellis, ...
    'InputFormat','Unquantized', ...
    'TracebackDepth', tblen, 'TerminationMethod','Truncated'); 

Decode_Data_STS = vitDecUNQUANT(LLR_STS);
% Decode_Data_STS_algo = vitDecUNQUANT(LLR_STS_algo);


%% Calculate metrics
[~, cur_ber_STS] = biterr(bits_out(:), Decode_Data_STS(:));
% [~, cur_ber_STS_algo] = biterr(bits_out(:), Decode_Data_STS_algo(:));


%% Write results
Ber_STS = [Ber_STS cur_ber_STS];
% Ber_STS_algo = [Ber_STS_algo cur_ber_STS_algo];


disp(SNR_dB)
end


%% Plotting results
[SNR_STS, Ber_STS] = Replace_Zeros(START_SNR + STEPS*STEP, Ber_STS);
% [SNR_STS_algo, Ber_STS_algo] = Replace_Zeros(st + SNRs*SNR_step, Ber_STS_algo);


% Plotting_multiple({SNR_STS_algo, SNR_STS}, {Ber_STS_algo, Ber_STS}, result_names, "SNR dB", "BER", "result", 1);
Plotting_multiple({SNR_STS}, {Ber_STS}, result_names, "SNR dB", "BER", "result", 1);
















