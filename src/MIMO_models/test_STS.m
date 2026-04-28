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
Nt = 3; Nr = 3;
STEPS = 0:6;
STEP = 2;
START_SNR = -1;
SNRS = START_SNR + STEPS*STEP;


Ber_STS_basic = [];
Ber_STS_puring = [];
Ber_STS_opt = [];

Time_STS_basic = [];
Time_STS_puring = [];
Time_STS_opt = [];

Clips_STS_basic = [];
Clips_STS_puring = [];
Clips_STS_opt = [];

for SNR_dB = SNRS


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
[LLR_STS_basic, cur_clips_STS_basic] = Solve_LLR_STS(info_symbols_out_channel, M, H, nVar, @qammod, 'basic');
Time_STS_basic = [Time_STS_basic toc];
Clips_STS_basic = [Clips_STS_basic cur_clips_STS_basic];

tic;
[LLR_STS_puring, cur_clips_STS_puring] = Solve_LLR_STS(info_symbols_out_channel, M, H, nVar, @qammod, 'puring');
Time_STS_puring = [Time_STS_puring toc];
Clips_STS_puring = [Clips_STS_puring cur_clips_STS_puring];

tic;
[LLR_STS_opt, cur_clips_STS_opt] = Solve_LLR_STS(info_symbols_out_channel, M, H, nVar, @qammod, 'opt');
Time_STS_opt = [Time_STS_opt toc];
Clips_STS_opt = [Clips_STS_opt cur_clips_STS_opt];


%% Viterbi-Decode message
vitDecUNQUANT = comm.ViterbiDecoder(trellis, ...
    'InputFormat','Unquantized', ...
    'TracebackDepth', tblen, 'TerminationMethod','Truncated'); 

Decode_Data_STS_basic = vitDecUNQUANT(LLR_STS_basic);
Decode_Data_STS_puring = vitDecUNQUANT(LLR_STS_puring);
Decode_Data_STS_opt = vitDecUNQUANT(LLR_STS_opt);


%% Calculate metrics
[~, cur_ber_STS_basic] = biterr(bits_out(:), Decode_Data_STS_basic(:));
[~, cur_ber_STS_puring] = biterr(bits_out(:), Decode_Data_STS_puring(:));
[~, cur_ber_STS_opt] = biterr(bits_out(:), Decode_Data_STS_opt(:));


%% Write results
Ber_STS_basic = [Ber_STS_basic cur_ber_STS_basic];
Ber_STS_puring = [Ber_STS_puring cur_ber_STS_puring];
Ber_STS_opt = [Ber_STS_opt cur_ber_STS_opt];

disp(SNR_dB)
end


%% Plotting results
[SNR_STS_basic, Ber_STS_basic] = Replace_Zeros(SNRS, Ber_STS_basic);
[SNR_STS_puring, Ber_STS_puring] = Replace_Zeros(SNRS, Ber_STS_puring);
[SNR_STS_opt, Ber_STS_opt] = Replace_Zeros(SNRS, Ber_STS_opt);


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

result_names = ["basic", "puring", "opt"];


% Plotting_multiple({SNR_STS_algo, SNR_STS}, {Ber_STS_algo, Ber_STS}, result_names, "SNR dB", "BER", "result", 1);
Plotting_multiple({SNR_STS_basic, SNR_STS_puring, SNR_STS_opt}, ...
    {Ber_STS_basic, Ber_STS_puring, Ber_STS_opt}, ...
    result_names, "SNR dB", "BER", "result", 1, directory_for_results);


% Plotting execution time curves
Plotting_multiple({SNRS, SNRS, SNRS}, ...
    {Time_STS_basic, Time_STS_puring, Time_STS_opt}, ...
    result_names, "SNR dB", "time sec", "Time compare", 1, directory_for_results);


% Plotting curvesof numb clips
Plotting_multiple({SNRS, SNRS, SNRS}, ...
    {Clips_STS_basic, Clips_STS_puring, Clips_STS_opt}, ...
    result_names, "SNR dB", "numb clips", "Clip compare", 1, directory_for_results);














