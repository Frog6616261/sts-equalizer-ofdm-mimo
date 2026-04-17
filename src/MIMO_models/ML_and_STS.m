clear all; close all; clc
%pkg load communications

%% parameters
rng(11); % random seed setter (for repeating the same results)

% viterbi params
n=2;k=1;L=7;
gen=[171 133];
trellis = poly2trellis(L,gen);
tblen=35;
tdhui = 'term';
opmode ='soft';


M = 4; % e.g. 2, 4, 8 -> PSK; 16, 64... -> QAM
numb_messages = 200;
Nt = 3; Nr = 3;
STEPS = 0:5;
STEP_sz = 2;
START_SNR = 1;
SNR_arr = START_SNR + STEPS*STEP_sz;


result_names = ["BER ML algo", "BER ML Max Log" "BER STS algo"];


Ber_ML_algo = [];
Ber_ML_Max_Log = [];
Ber_STS_algo = [];


time_names = ["time ML algo", "time ML Max Log" "time STS algo"];

time_ML_algo = [];
time_ML_Max_Log = [];
time_STS_algo = [];


clip_names = ["clips STS opt"];

clips_STS_algo = [];


%profile on;

for CUR_STEP = STEPS

SNR_dB = START_SNR + CUR_STEP*STEP_sz;


%% Generate Messsage and References simbols
enc = comm.ConvolutionalEncoder(trellis);
[bits_out, numb_bits] = Generate_messages_bits(Nt, numb_messages, M);
cod_vect = enc(bits_out(:));
mod_vect = qammod(cod_vect(:), M, InputType="bit");
Mod_symbols = reshape(mod_vect, Nt, []);


%% Channel fading and Antennas interfernce
h = Generate_random_channel_matrix(Nt,Nr);
% h = Generate_random_flat_fading_channel_matrix(Nt, Nr);
% h = Generate_random_channel_matrix_notHermitian(Nt,Nr, 0.001, 2);
% h = [-2, 0.00001+1i ; -0.00001, 1];
% h = [-2, 0.00001+1i, 1; -0.00001, 1, 0.001 + 0.01i; 0, 1 + 2i, 0.001 + 1i];
% h = [ 0.5 + 1i,   -0.2,        0.001 + 0.01i, 1 - 0.5i;
%      -0.0001,      1 + 0.5i,   0.3 + 0.2i,    0.001;
%       0.01 + 0.3i, 0.2,        -0.5 + 0.1i,   1 + 0.001i;
%       0.2 - 0.1i,  0.001,      1 + 0.2i,      -0.3 + 0.4i ];

H = h; % find by pilots symbols
info_symbols_antenna_interference = h*Mod_symbols;


%% Add the AWGN (block "AWGN")
[info_symbols_out_channel, nVar] = ADD_AWGN_MIMO(info_symbols_antenna_interference, SNR_dB);


%% Solve LLR
% ML
tic;
[LLR_ML_algo, exp_algo] = Solve_LLR_ML_algo(info_symbols_out_channel, M, H, nVar, @qammod);
time_ML_algo = [time_ML_algo toc];

tic;
[LLR_ML_Max_Log, la_ml, g_ml] = Solve_LLR_ML_Max_Log(info_symbols_out_channel, M, H, nVar, @qammod);
time_ML_Max_Log = [time_ML_Max_Log toc];


% STS
tic;
[LLR_STS_algo, cur_numb_clips_STS_algo, la_algo, g_algo] = Solve_LLR_STS_algo(info_symbols_out_channel, M, H, nVar, @qammod);
time_STS_algo = [time_STS_algo toc];

clips_STS_algo = [clips_STS_algo cur_numb_clips_STS_algo];


%% Viterbi-Decode message
vitDecUNQUANT = comm.ViterbiDecoder(trellis, ...
    'InputFormat','Unquantized', ...
    'TracebackDepth', tblen, 'TerminationMethod','Truncated'); 

Decode_Data_ML_algo = vitDecUNQUANT(LLR_ML_algo);
Decode_Data_ML_Max_Log = vitDecUNQUANT(LLR_ML_Max_Log);

Decode_Data_STS_algo = vitDecUNQUANT(LLR_STS_algo(:));


%% Calculate metrics
[~, cur_ber_ML_algo] = biterr(bits_out(:), Decode_Data_ML_algo(:));
[~, cur_ber_ML_Max_Log] = biterr(bits_out(:), Decode_Data_ML_Max_Log(:));

[~, cur_ber_STS_algo] = biterr(bits_out(:), Decode_Data_STS_algo(:));


%% Write results
Ber_ML_algo = [Ber_ML_algo cur_ber_ML_algo];
Ber_ML_Max_Log = [Ber_ML_Max_Log cur_ber_ML_Max_Log];

Ber_STS_algo = [Ber_STS_algo cur_ber_STS_algo];


disp(SNR_dB)
end

% profile off;
% profile viewer;

%% Plotting results
[SNR_ML_algo, Ber_ML_algo] = Replace_Zeros(SNR_arr, Ber_ML_algo);
[SNR_ML_Max_Log, Ber_ML_Max_Log] = Replace_Zeros(SNR_arr, Ber_ML_Max_Log);

[SNR_STS_algo, Ber_STS_algo] = Replace_Zeros(SNR_arr, Ber_STS_algo);


%% Plotting and save results

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


% Plotting BER
Plotting_multiple({SNR_ML_algo, SNR_ML_Max_Log, SNR_STS_algo}, {Ber_ML_algo, Ber_ML_Max_Log, Ber_STS_algo}, result_names, "SNR dB", "BER", "Ber compare", 1, directory_for_results);


% Plotting execution time curves
Plotting_multiple({SNR_arr, SNR_arr, SNR_arr}, {time_ML_algo, time_ML_Max_Log, time_STS_algo}, time_names, "SNR dB", "time sec", "Time compare", 1, directory_for_results);


% Plotting curvesof numb clips
Plotting_multiple({SNR_arr}, {clips_STS_algo}, clip_names, "SNR dB", "numb clips", "Clip compare", 1, directory_for_results);






