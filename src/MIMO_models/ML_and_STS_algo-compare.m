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


M = 16; % e.g. 2, 4, 8 -> PSK; 16, 64... -> QAM
numb_messages = 500;
Nt = 2; Nr = 2;
STEPS = 0:6;
STEP_sz = 2;
START_SNR = 1;
SNR_arr = START_SNR + STEPS*STEP_sz;


% result_names = ["BER ML 1", "BER ML 2"];
% result_names = ["BER ML 1", "BER ML 3"];
% result_names = ["BER ML 1", "BER STS wQR", "BER STS"];
% result_names = ["BER ML", "BER ML 2", "BER ML algo", "BER STS opt"];
% result_names = ["BER ML", "BER ML algo", "BER STS opt"];
% result_names = ["BER ML", "BER ML algo", "BER STS opt", "BER STS"];
result_names = ["BER ML algo", "BER STS opt"];
% result_names = ["BER ML", "BER ML 2", "BER ML algo", "BER STS", "BER STS opt"];


Ber_ML_1 = [];
Ber_ML_2 = [];
Ber_ML_3 = [];
Ber_ML_algo = [];
Ber_STS_wQR = [];
Ber_STS = [];
Ber_STS_opt = [];

% time_names = ["time ML", "time ML 2", "time ML algo", "time STS opt"];
% time_names = ["time ML", "time ML algo", "time STS opt"];
% time_names = ["time ML", "time ML algo", "time STS opt", "time STS"];
time_names = ["time ML algo", "time STS opt"];
% time_names = ["time ML", "time ML 2", "time ML algo", "time STS", "time STS opt"];
% time_names = ["time ML", "time STS"];

time_ML_1 = [];
time_ML_2 = [];
time_ML_algo = [];
time_ML_Max_Log = []
time_STS = [];
time_STS_opt = [];


% clip_names = ["clips ML", "clips ML 2", "clips ML algo", "clips STS", "clips STS opt"];
clip_names = ["clips STS opt"];
% clip_names = ["clips STS opt", "clips STS"];

clips_ML_1 = [];
clips_ML_2 = [];
clips_ML_algo = [];
clips_STS = [];
clips_STS_opt = [];


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
% % ML
% tic;
% [LLR_ML_1, exp_1] = Solve_LLR_ML(info_symbols_out_channel, M, H, nVar);
% time_ML_1 = [time_ML_1 toc];

% tic;
% [LLR_ML_2, ~] = Solve_LLR_ML(info_symbols_out_channel, M, H, nVar);
% time_ML_2 = [time_ML_2 toc];

tic;
[LLR_ML_algo, exp_algo] = Solve_LLR_ML_algo(info_symbols_out_channel, M, H, nVar, @qammod);
time_ML_algo = [time_ML_algo toc];


% % STS
% tic;
% [LLR_STS, cur_numb_clips_STS, la, g] = Solve_LLR_STS(info_symbols_out_channel, M, H, nVar, @qammod);
% time_STS = [time_STS toc];
% 
% clips_STS = [clips_STS cur_numb_clips_STS];

tic;
[LLR_STS_opt, cur_numb_clips_STS_opt, la_opt, g_opt] = Solve_LLR_STS_opt(info_symbols_out_channel, M, H, nVar, @qammod);
time_STS_opt = [time_STS_opt toc];

clips_STS_opt = [clips_STS_opt cur_numb_clips_STS_opt];


%% Viterbi-Decode message
vitDecUNQUANT = comm.ViterbiDecoder(trellis, ...
    'InputFormat','Unquantized', ...
    'TracebackDepth', tblen, 'TerminationMethod','Truncated'); 

% Decode_Data_ML_1 = vitDecUNQUANT(LLR_ML_1);
% Decode_Data_ML_2 = vitDecUNQUANT(LLR_ML_2);
Decode_Data_ML_algo = vitDecUNQUANT(LLR_ML_algo);

% Decode_Data_STS = vitDecUNQUANT(LLR_STS);
Decode_Data_STS_opt = vitDecUNQUANT(LLR_STS_opt);
% Decode_Data_STS_wQR = vitDecUNQUANT(LLR_STS_wQR);


%% Calculate metrics
% [~, cur_ber_ML_1] = biterr(bits_out(:), Decode_Data_ML_1(:));
% [~, cur_ber_ML_2] = biterr(bits_out(:), Decode_Data_ML_2(:));
[~, cur_ber_ML_algo] = biterr(bits_out(:), Decode_Data_ML_algo(:));

% [~, cur_ber_STS] = biterr(bits_out(:), Decode_Data_STS(:));
[~, cur_ber_STS_opt] = biterr(bits_out(:), Decode_Data_STS_opt(:));


%% Write results
% Ber_ML_1 = [Ber_ML_1 cur_ber_ML_1];
% Ber_ML_2 = [Ber_ML_2 cur_ber_ML_2];
Ber_ML_algo = [Ber_ML_algo cur_ber_ML_algo];

% Ber_STS = [Ber_STS cur_ber_STS];
Ber_STS_opt = [Ber_STS_opt cur_ber_STS_opt];


disp(SNR_dB)
end

profile off;
profile viewer;

%% Plotting results
% [SNR_ML_1, Ber_ML_1] = Replace_Zeros(SNR_arr, Ber_ML_1);
% [SNR_ML_2, Ber_ML_2] = Replace_Zeros(SNR_arr, Ber_ML_2);
[SNR_ML_algo, Ber_ML_algo] = Replace_Zeros(SNR_arr, Ber_ML_algo);

% [SNR_STS, Ber_STS] = Replace_Zeros(SNR_arr, Ber_STS);
[SNR_STS_opt, Ber_STS_opt] = Replace_Zeros(SNR_arr, Ber_STS_opt);
% [SNR_STS_wQR, Ber_STS_wQR] = Replace_Zeros(st + SNRs*2, Ber_STS_wQR);


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
% Plotting_multiple({SNR_ML_1, SNR_ML_algo, SNR_STS_opt, SNR_STS}, {Ber_ML_1, Ber_ML_algo, Ber_STS_opt, Ber_STS}, result_names, "SNR dB", "BER", "BER compare", 1, directory_for_results);
% Plotting_multiple({SNR_ML_1, SNR_ML_algo, SNR_STS_opt}, {Ber_ML_1, Ber_ML_algo, Ber_STS_opt}, result_names, "SNR dB", "BER", "BER compare", 1, directory_for_results);
Plotting_multiple({SNR_ML_algo, SNR_STS_opt}, {Ber_ML_algo, Ber_STS_opt}, result_names, "SNR dB", "BER", "result", 1, directory_for_results);


% Plotting execution time curves
% Plotting_multiple({SNR_arr, SNR_arr, SNR_arr, SNR_arr}, {time_ML_1, time_ML_algo, time_STS_opt, time_STS}, time_names, "SNR dB", "time sec", "Time compare", 1, directory_for_results);
% Plotting_multiple({SNR_arr, SNR_arr, SNR_arr}, {time_ML_1, time_ML_algo, time_STS_opt}, time_names, "SNR dB", "time sec", "Time compare", 1, directory_for_results);
Plotting_multiple({SNR_arr, SNR_arr}, {time_ML_algo, time_STS_opt}, time_names, "SNR dB", "time sec", "Time compare", 1, directory_for_results);


% Plotting curvesof numb clips
% Plotting_multiple({SNR_arr, SNR_arr}, {clips_STS_opt, clips_STS}, clip_names, "SNR dB", "numb clips", "Clip compare", 1, directory_for_results);
Plotting_multiple({SNR_arr}, {clips_STS_opt}, clip_names, "SNR dB", "numb clips", "Clip compare", 1, directory_for_results);






