clear all; close all; clc
%pkg load communications

%% parameters
rng(5); % random seed setter (for repeating the same results)

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


% viterbi params
n=2;k=1;L=7;
gen=[171 133];
trellis = poly2trellis(L,gen);
tblen=6;
tdhui = 'term';
opmode ='soft';


M = 16; % e.g. 2, 4, 8 -> PSK; 16, 64... -> QAM
numb_messages = 1000;
Nt = 2;Nr = 2;
STEPS = 0:9;
STEP_sz = 2;
START_SNR = 4;
SNRs = START_SNR + STEPS*STEP_sz;


Ber_ML = [];
Ber_ML_2 = [];
Ber_ML_algo = [];
Ber_ML_Max_Log = [];


for SNR_dB = SNRs


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
LLR_ML = Solve_LLR_ML(info_symbols_out_channel, M, H, nVar, @qammod, 'sum-exp');
LLR_ML_algo = Solve_LLR_ML(info_symbols_out_channel, M, H, nVar, @qammod, 'algo');
LLR_ML_maxlog = Solve_LLR_ML(info_symbols_out_channel, M, H, nVar, @qammod, 'max-log');


%% Viterbi-Decode message
vitDecUNQUANT = comm.ViterbiDecoder(trellis, ...
    'InputFormat','Unquantized', ...
    'TracebackDepth', tblen); 

Decode_Data_ML = vitDecUNQUANT(LLR_ML);
Decode_Data_ML_algo = vitDecUNQUANT(LLR_ML_algo);
Decode_Data_ML_Max_Log = vitDecUNQUANT(LLR_ML_maxlog);


%% Calculate metrics
[~, cur_ber_ML] = biterr(transpose(bits_out(1:end-tblen)), Decode_Data_ML(tblen+1:end));
[~, cur_ber_ML_algo] = biterr(transpose(bits_out(1:end-tblen)), Decode_Data_ML_algo(tblen+1:end));
[~, cur_ber_ML_Max_Log] = biterr(transpose(bits_out(1:end-tblen)), Decode_Data_ML_Max_Log(tblen+1:end));


%% Write results
Ber_ML = [Ber_ML cur_ber_ML];
Ber_ML_algo = [Ber_ML_algo cur_ber_ML_algo];
Ber_ML_Max_Log = [Ber_ML_Max_Log cur_ber_ML_Max_Log];


disp(SNR_dB)
end


%% Plotting results
[SNR_ML, Ber_ML] = Replace_Zeros(SNRs, Ber_ML);
[SNR_ML_algo, Ber_ML_algo] = Replace_Zeros(SNRs, Ber_ML_algo);
[SNR_ML_Max_Log, Ber_ML_Max_Log] = Replace_Zeros(SNRs, Ber_ML_Max_Log);

result_names = ["ML", "ML algo", "ML MaxLog"];


Plotting_multiple({SNR_ML, SNR_ML_algo, SNR_ML_Max_Log}, {Ber_ML, Ber_ML_algo, Ber_ML_Max_Log}, result_names, "SNR dB", "BER", "result", 1, directory_for_results);












