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
numb_messages = 500;
Nt = 2; Nr = 2;
STEPS = 0:6;
STEP_sz = 2;
START_SNR = 10;
SNRs = START_SNR + STEPS*STEP_sz;


Ber_ZF = [];
Ber_MMSE = [];
Ber_ML = [];
Ber_STS = [];

time_ZF = [];
time_MMSE = [];
time_ML = [];
time_STS = [];

clips_STS = [];


profile on;

for SNR_dB = SNRs

%% Generate Messsage and References simbols
enc = comm.ConvolutionalEncoder(trellis);
[bits_out, numb_bits] = Generate_messages_bits(Nt, numb_messages, M);
cod_vect = enc(bits_out(:));
mod_vect = qammod(cod_vect(:), M, InputType="bit");
Mod_symbols = reshape(mod_vect, Nt, []);


%% Channel fading and Antennas interfernce
h = Generate_random_flat_fading_channel_matrix(Nt, Nr);

H = h; % try channel
info_symbols_antenna_interference = h*Mod_symbols;


%% Add the AWGN (block "AWGN")
[info_symbols_out_channel, nVar] = ADD_AWGN_MIMO(info_symbols_antenna_interference, SNR_dB);


%% Equalizers by channel matrix
% Zero-Forcing
tic;
info_symbols_equalized_ZF = reshape(use_ZF_equalizer(info_symbols_out_channel, H, Nt), [], 1);
LLR_ZF = qamdemod(info_symbols_equalized_ZF, M, OutputType="llr");
time_ZF = [time_ZF toc];

% MMSE
tic;
info_symbols_equalized_MMSE = reshape(use_MMSE_equalizer(info_symbols_out_channel, H, Nr, Nt, SNR_dB, 0), [], 1);
LLR_MMSE = qamdemod(info_symbols_equalized_MMSE, M, OutputType="llr");
time_MMSE = [time_MMSE toc];


%% Equalizers ML algorithms
tic;
LLR_ML = Solve_LLR_ML(info_symbols_out_channel, M, H, nVar, @qammod, 'sum-exp');
time_ML = [time_ML toc];


%% Equalizers MAP algorithms
tic;
[LLR_STS, numb_clips_STS] = Solve_LLR_STS(info_symbols_out_channel, M, H, nVar, @qammod, 'opt');
time_STS = [time_STS toc];

clips_STS = [clips_STS numb_clips_STS];


%% Viterbi-Decode message
vitDecUNQUANT = comm.ViterbiDecoder(trellis, ...
    'InputFormat','Unquantized', ...
    'TracebackDepth', tblen, 'TerminationMethod','Truncated'); 

Decode_Data_ZF = vitDecUNQUANT(LLR_ZF);
Decode_Data_MMSE = vitDecUNQUANT(LLR_MMSE);
Decode_Data_ML = vitDecUNQUANT(LLR_ML);
Decode_Data_STS = vitDecUNQUANT(LLR_STS);


%% Calculate metrics
[~, ber_ZF] = biterr(bits_out(:), Decode_Data_ZF(:));
[~, ber_MMSE] = biterr(bits_out(:), Decode_Data_MMSE(:));
[~, cur_ber_ML] = biterr(bits_out(:), Decode_Data_ML(:));
[~, cur_ber_STS] = biterr(bits_out(:), Decode_Data_STS(:));


%% Write results
Ber_ZF = [Ber_ZF ber_ZF];
Ber_MMSE = [Ber_MMSE ber_MMSE];
Ber_ML = [Ber_ML cur_ber_ML];
Ber_STS = [Ber_STS cur_ber_STS];


disp(SNR_dB)
end
profile off;
profile viewer;


%% Plotting results
result_names = ["ZF", "MMSE", "ML", "STS"];
time_names = ["ZF", "MMSE", "ML", "STS"];
clip_names = ["STS"];


% replase zeros ber
[SNR_ZF, Ber_ZF] = Replace_Zeros(SNRs, Ber_ZF);
[SNR_MMSE, Ber_MMSE] = Replace_Zeros(SNRs, Ber_MMSE);
[SNR_ML, Ber_ML] = Replace_Zeros(SNRs, Ber_ML);
[SNR_STS, Ber_STS] = Replace_Zeros(SNRs, Ber_STS);
 

% create result directory
time_stamp_str = char(datetime('now'));
for i = 1:strlength(time_stamp_str)
    if (time_stamp_str(i) == '-' || time_stamp_str(i) == ':')
        time_stamp_str(i) = '.'; 
    end
end

folder = "results";
directory_for_results = folder + "\" + time_stamp_str; 

if ~exist(folder, "dir"), mkdir(folder); end
mkdir(directory_for_results);


% plotting ber
Plotting_multiple({SNR_ZF, SNR_MMSE, SNR_ML, SNR_STS}, {Ber_ZF, Ber_MMSE, Ber_ML, Ber_STS}, result_names, "SNR dB", "BER", "result", 1, directory_for_results);

% plotting execution time curves
Plotting_multiple({SNRs, SNRs, SNRs, SNRs}, {time_ZF, time_MMSE, time_ML, time_STS}, time_names, "SNR dB", "time sec", "Time compare", 1, directory_for_results);

% plotting curves of numb clips
Plotting_multiple({SNRs}, {clips_STS}, clip_names, "SNR dB", "numb clips", "Clip compare", 1, directory_for_results);











