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
numb_messages = 50;
Nt = 3; Nr = 3;
STEPS = 0:4;
STEP_sz = 3;
START_SNR = 4;

result_names = ["BER_SD", "BER_ZF", "BER_MMSE", "BER ML 1", "BER STS"];
result_names = ["BER ZF", "BER MMSE", "BER ML", "BER STS"];

Ber_SD = [];
Ber_ZF = [];
Ber_MMSE = [];
Ber_ML = [];
Ber_STS = [];


time_names = ["time ZF", "time MMSE", "time ML", "time STS"];

time_SD = [];
time_ZF = [];
time_MMSE = [];
time_ML = [];
time_STS = [];

profile on;

for CUR_STEP = STEPS

SNR_dB = START_SNR + CUR_STEP*STEP_sz;

%% Generate Messsage and References simbols
enc = comm.ConvolutionalEncoder(trellis);
[bits_out, numb_bits] = Generate_messages_bits(Nt, numb_messages, M);
cod_vect = enc(bits_out(:));
mod_vect = qammod(cod_vect(:), M, InputType="bit");
Mod_symbols = reshape(mod_vect, Nt, []);


%% Channel fading and Antennas interfernce
% h = Generate_random_channel_matrix(Nt,Nr);
h = Generate_random_channel_matrix_notHermitian(Nt,Nr, 0.001, 2);
% h = [-2, 0.00001+1i ; -0.00001, 1];
h = [-2, 0.00001+1i, 1; -0.00001, 1, 0.001 + 0.01i; 0, 1 + 2i, 0.001 + 1i];
% h = [ 0.5 + 1i,   -0.2,        0.001 + 0.01i, 1 - 0.5i;
%      -0.0001,      1 + 0.5i,   0.3 + 0.2i,    0.001;
%       0.01 + 0.3i, 0.2,        -0.5 + 0.1i,   1 + 0.001i;
%       0.2 - 0.1i,  0.001,      1 + 0.2i,      -0.3 + 0.4i ];

H = h; % find by pilots symbols
info_symbols_antenna_interference = h*Mod_symbols;


%% Add the AWGN (block "AWGN")
[info_symbols_out_channel, nVar] = ADD_AWGN_MIMO(info_symbols_antenna_interference, SNR_dB);


%% Equalizers
info_symbols_equalized_ZF = reshape(use_ZF_equalizer(info_symbols_out_channel, H, Nt), [], 1);
info_symbols_equalized_MMSE = reshape(use_my_MMSE_equalizer(info_symbols_out_channel, H, Nr, Nt, SNR_dB, 0), [], 1);
% info_synb_SD = reshape(SD_message(H,info_symbols_out_channel,M),[],1);


%% Solve LLR
% LL_SD = qamdemod(info_synb_SD, M, OutputType="llr");
tic;
LLR_intern_ZF = qamdemod(info_symbols_equalized_ZF, M, OutputType="llr");
time_ZF = [time_ZF toc];

tic;
LLR_intern_MMSE = qamdemod(info_symbols_equalized_MMSE, M, OutputType="llr");
time_MMSE = [time_MMSE toc];

tic;
[LLR_ML, ~] = Solve_LLR_ML(info_symbols_out_channel, M, H, nVar);
time_ML = [time_ML toc];

tic;
[LLR_STS, numb_clipping] = Solve_LLR_STS(info_symbols_out_channel, M, H, nVar, @qammod);
time_STS = [time_STS toc];
disp(numb_clipping);


%% Viterbi-Decode message
vitDecUNQUANT = comm.ViterbiDecoder(trellis, ...
    'InputFormat','Unquantized', ...
    'TracebackDepth', tblen, 'TerminationMethod','Truncated'); 

% Decode_Data_SD = vitDecUNQUANT(LL_SD);
Decode_Data_ZF_int = vitDecUNQUANT(LLR_intern_ZF);
Decode_Data_MMSE_int = vitDecUNQUANT(LLR_intern_MMSE);
Decode_Data_ML = vitDecUNQUANT(LLR_ML);
Decode_Data_STS = vitDecUNQUANT(LLR_STS);


%% Calculate metrics
% [~, ber_SD] = biterr(transpose(bits_out(1:end-tblen)), Decode_Data_SD(tblen+1:end));
[~, ber_ZF_int] = biterr(bits_out(:), Decode_Data_ZF_int(:));
[~, ber_MMSE_int] = biterr(bits_out(:), Decode_Data_MMSE_int(:));
[~, cur_ber_ML] = biterr(bits_out(:), Decode_Data_ML(:));
[~, cur_ber_STS] = biterr(bits_out(:), Decode_Data_STS(:));


%% Write results
% Ber_SD = [Ber_SD ber_SD];
Ber_ZF = [Ber_ZF ber_ZF_int];
Ber_MMSE = [Ber_MMSE ber_MMSE_int];
Ber_ML = [Ber_ML cur_ber_ML];
Ber_STS = [Ber_STS cur_ber_STS];


disp(SNR_dB)
end
profile off;
profile viewer;

%% Plotting results
% [SNR_SD, Ber_SD] = Replace_Zeros(START_SNR + STEPS*STEP_sz, Ber_SD);
[SNR_ZF, Ber_ZF] = Replace_Zeros(START_SNR + STEPS*STEP_sz, Ber_ZF);
[SNR_MMSE, Ber_MMSE] = Replace_Zeros(START_SNR + STEPS*STEP_sz, Ber_MMSE);
[SNR_ML, Ber_ML] = Replace_Zeros(START_SNR + STEPS*STEP_sz, Ber_ML);
[SNR_STS, Ber_STS] = Replace_Zeros(START_SNR + STEPS*STEP_sz, Ber_STS);

%% Plotting BER
% Plotting_multiple({SNR_SD, SNR_ZF, SNR_MMSE, SNR_ML_1, SNR_STS}, {Ber_SD, Ber_ZF, Ber_MMSE, Ber_ML_1, Ber_STS}, result_names, "SNR dB", "BER", "result", 1);
Plotting_multiple({SNR_ZF, SNR_MMSE, SNR_ML, SNR_STS}, {Ber_ZF, Ber_MMSE, Ber_ML, Ber_STS}, result_names, "SNR dB", "BER", "result", 1);


%% Plotting execution time curves
Plotting_multiple({START_SNR + STEPS*STEP_sz, START_SNR + STEPS*STEP_sz, START_SNR + STEPS*STEP_sz, START_SNR + STEPS*STEP_sz}, {time_ZF, time_MMSE, time_ML, time_STS}, time_names, "SNR dB", "time sec", "Time compare", 1);





