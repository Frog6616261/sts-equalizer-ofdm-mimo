        clear all; close all; clc
%pkg load communications

%% parameters
rng(5); % random seed setter (for repeating the same results)

% viterbi params
n=2;k=1;L=7;
gen=[171 133];
trellis = poly2trellis(L,gen);
tblen=6;
tdhui = 'term';
opmode ='soft';


M = 16; % e.g. 2, 4, 8 -> PSK; 16, 64... -> QAM
numb_messages = 1000;
Nt = 3;Nr = 3;
SNRs = 1:10;


%result_names = ["BER ML 1", "BER ML 2"];
%result_names = ["BER ML 1", "BER ML 3"];
result_names = ["BER ML 1"];
%result_names = ["BER ML 2"];.


Ber_ML_1 = [];
Ber_ML_2 = [];
Ber_ML_3 = [];

numb_ml = [];

st = 0;

for SNR_dBs = SNRs

SNR_dB = st + SNR_dBs*2;

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
[LLR_ML_1, ~] = Solve_LLR_ML(info_symbols_out_channel, M, H, nVar);
%[LLR_ML_2, ~] = Solve_LLR_ML2(info_symbols_out_channel, M, H, nVar);
% [LLR_ML_3] = Solve_LLR_ML3(info_symbols_out_channel, M, H, nVar);


%% Viterbi-Decode message
vitDecUNQUANT = comm.ViterbiDecoder(trellis, ...
    'InputFormat','Unquantized', ...
    'TracebackDepth', tblen); 

Decode_Data_ML_1 = vitDecUNQUANT(LLR_ML_1);
% Decode_Data_ML_2 = vitDecUNQUANT(LLR_ML_2);
% Decode_Data_ML_3 = vitDecUNQUANT(LLR_ML_3);


%% Calculate metrics
[~, cur_ber_ML_1] = biterr(transpose(bits_out(1:end-tblen)), Decode_Data_ML_1(tblen+1:end));
% [~, cur_ber_ML_2] = biterr(transpose(bits_out(1:end-tblen)), Decode_Data_ML_2(tblen+1:end));
% [~, cur_ber_ML_3] = biterr(transpose(bits_out(1:end-tblen)), Decode_Data_ML_3(tblen+1:end));


%% Write results
Ber_ML_1 = [Ber_ML_1 cur_ber_ML_1];
% Ber_ML_2 = [Ber_ML_2 cur_ber_ML_2];
% Ber_ML_3 = [Ber_ML_3 cur_ber_ML_3];


%% Solve numb not same bits
numb_ml = [numb_ml (find(bits_out(1:end-tblen)' ~= Decode_Data_ML_1(tblen+1:end)))' + tblen];

disp(SNR_dB)
end


%% Plotting results
[SNR_ML_1, Ber_ML_1] = Replace_Zeros(st + SNRs*2, Ber_ML_1);
% Ber_ML_2 = Replace_Zeros(Ber_ML_2);
% Ber_ML_3 = Replace_Zeros(Ber_ML_3);


Plotting_multiple({SNR_ML_1}, {Ber_ML_1}, result_names, "SNR dB", "BER", "result", 1);












