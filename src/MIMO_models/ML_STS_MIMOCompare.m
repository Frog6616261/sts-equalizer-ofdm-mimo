clear all; close all; clc
%pkg load communications

%% parameters
rng(11); % random seed setter (for repeating the same results)

MIMO_LENGTH = 2:3; % 2:6
average_time_ML_algo = [];
average_time_STS_opt = [];


% create result directory
time_stamp_str = char(datetime('now'));
for i = 1:strlength(time_stamp_str)
    if (time_stamp_str(i) == '-' || time_stamp_str(i) == ':')
        time_stamp_str(i) = '.'; 
    end
end

folder = "results";
directory_for_results = folder + "\" + time_stamp_str + "ml_ml_and_sts"; 

if ~exist(folder, "dir"), mkdir(folder); end
mkdir(directory_for_results);


for mimo_sz = MIMO_LENGTH

% viterbi params
n=2;k=1;L=7;
gen=[171 133];
trellis = poly2trellis(L,gen);
tblen=35;
tdhui = 'term';
opmode ='soft';


M = 16; % e.g. 2, 4, 8 -> PSK; 16, 64... -> QAM
numb_messages = 50;
Nt = mimo_sz; Nr = mimo_sz;
STEPS = 0:3;
STEP_sz = 3;
START_SNR = 4;
SNR_arr = START_SNR + STEPS*STEP_sz;


result_names = ["BER ML Max-Log", "BER STS"];


Ber_ML_Max_Log = [];
Ber_STS = [];

time_names = ["time ML Max-Log", "time STS"];

time_ML_Max_Log = [];
time_STS = [];

clip_names = ["clips STS opt"];

clips_ML_Max_Log = [];
clips_STS = [];


for CUR_STEP = STEPS

SNR_dB = START_SNR + CUR_STEP*STEP_sz;


%% Generate Messsage and References simbols
enc = comm.ConvolutionalEncoder(trellis);
[bits_out, numb_bits] = Generate_messages_bits(Nt, numb_messages, M);
cod_vect = enc(bits_out(:));
mod_vect = qammod(cod_vect(:), M, InputType="bit");
Mod_symbols = reshape(mod_vect, Nt, []);


%% Channel fading and Antennas interfernce
h = Generate_random_flat_fading_channel_matrix(Nt, Nr);
H = h; % find by pilots symbols
info_symbols_antenna_interference = h*Mod_symbols;


%% Add the AWGN (block "AWGN")
[info_symbols_out_channel, nVar] = ADD_AWGN_MIMO(info_symbols_antenna_interference, SNR_dB);


%% Solve LLR
tic;
LLR_ML_Max_Log = Solve_LLR_ML(info_symbols_out_channel, M, H, nVar, @qammod, 'max-log');
time_ML_Max_Log = [time_ML_Max_Log toc];

tic;
[LLR_STS, cur_numb_clips_STS] = Solve_LLR_STS(info_symbols_out_channel, M, H, nVar, @qammod, 'opt');
time_STS = [time_STS toc];

clips_STS = [clips_STS cur_numb_clips_STS];


%% Viterbi-Decode message
vitDecUNQUANT = comm.ViterbiDecoder(trellis, ...
    'InputFormat','Unquantized', ...
    'TracebackDepth', tblen, 'TerminationMethod','Truncated'); 

Decode_Data_ML_Max_Log = vitDecUNQUANT(LLR_ML_Max_Log(:));
Decode_Data_STS = vitDecUNQUANT(LLR_STS(:));


%% Calculate metrics
[~, cur_ber_ML_algo] = biterr(bits_out(:), Decode_Data_ML_Max_Log(:));

[~, cur_ber_STS_opt] = biterr(bits_out(:), Decode_Data_STS(:));


%% Write results
Ber_ML_Max_Log = [Ber_ML_Max_Log cur_ber_ML_algo];

Ber_STS = [Ber_STS cur_ber_STS_opt];


disp(SNR_dB)
end



%% Plotting results
[SNR_ML_Max_Log, Ber_ML_Max_Log] = Replace_Zeros(SNR_arr, Ber_ML_Max_Log);
[SNR_STS, Ber_STS] = Replace_Zeros(SNR_arr, Ber_STS);


%% Plotting and save results

% Plotting BER
Plotting_multiple({SNR_ML_Max_Log, SNR_STS}, {Ber_ML_Max_Log, Ber_STS}, result_names, "SNR dB", "BER", ("result mimo=" + string(mimo_sz)), 1, directory_for_results);


% Plotting execution time curves
Plotting_multiple({SNR_arr, SNR_arr}, {time_ML_Max_Log, time_STS}, time_names, "SNR dB", "time sec", ("Time compare mimo=" + string(mimo_sz)), 1, directory_for_results);


% Plotting curvesof numb clips
Plotting_multiple({SNR_arr}, {clips_STS}, clip_names, "SNR dB", "numb clips", ("Clip compare mimo=" + string(mimo_sz)), 1, directory_for_results);


%% Save average time for current mimo
average_time_STS_opt = [average_time_STS_opt mean(time_STS)];
average_time_ML_algo = [average_time_ML_algo mean(time_ML_Max_Log)];

disp("mimo="+string(mimo_sz) + "  is done");
end

% Plotting execution time curves
Plotting_multiple({MIMO_LENGTH, MIMO_LENGTH}, {average_time_ML_algo, average_time_STS_opt}, time_names, "MIMO sz", "time sec", "AVERAGE Time compare", 1, directory_for_results);


