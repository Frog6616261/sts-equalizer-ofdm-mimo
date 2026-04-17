clear all; close all; clc
%pkg load communications

%% parameters
rng(5); % random seed setter (for repeating the same results)


M = 4; % e.g. 2, 4, 8 -> PSK; 16, 64... -> QAM
numb_messages = 10000;
Nt = 2;
Nr = 2;
count_bits = numb_messages * Nt * log2(M); disp(count_bits);
SNR = -2:1:20;
plt_const_for_snr = 16;

% viterbi coder/encoder params
constraint_length = 7; % Длина ограничения (Constraint Length)
poly = [171 133]; % Полиномы кодера
trellis = poly2trellis(constraint_length, poly);
tbdepth = 32;
opmode = "trunc";
dectype = "hard";

result_names = ["BER ZF", "BER MMSE", "EVM ZF", "EVM MMSE", "SNR dB"];
result = [];


%% Open File
fileID = fopen('metrics.txt','w');
fprintf(fileID, '%s\t%s\t%s\t%s\t%s\n', "BER_ZF", "BER_MMSE", "EVM_ZF", "EVM_MMSE", "SNR_dB");


for SNR_dB = SNR

%% Generate Messsage and References simbols
enc = comm.ConvolutionalEncoder(trellis);
[bits_out, numb_bits] = Generate_messages_bits(Nt, numb_messages, M);
bits_conv = enc(bits_out(:));
mod_symbols = pskmod(bits_conv, M, pi/4, InputType="bit");
Mod_symbols = reshape(mod_symbols, Nt, []);
pilots_simbols = Generate_pilots_symbols(Nt);


%% Channel fading and Antennas interfernce
%h = Generate_random_channel_matrix(Nt,Nr);
%h = eye(Nt);
h = [-2, 0.00001 + 1i; -0.00001, 1];
info_symbols_antenna_interference = h*Mod_symbols;
pilots_symbols_antenna_interference = h*pilots_simbols.';


%% Add the AWGN (block "AWGN")
[info_symbols_out_channel, ~]= ADD_AWGN_MIMO(info_symbols_antenna_interference, SNR_dB);
[pilots_symbols_out_channel, ~] = ADD_AWGN_MIMO(pilots_symbols_antenna_interference, SNR_dB);
 
if SNR_dB == plt_const_for_snr
    Plotting_QAM_symbols(info_symbols_out_channel, true);
end

%% Equalizer training and using
H = h;

info_symbols_equalized_ZF = use_ZF_equalizer(info_symbols_out_channel, H, Nt);
info_symbols_equalized_MMSE = use_my_MMSE_equalizer(info_symbols_out_channel, H, Nr, Nt, SNR_dB, 0);

if SNR_dB == plt_const_for_snr
    Plotting_QAM_symbols_for_equalasers(info_symbols_equalized_ZF, info_symbols_equalized_MMSE, plt_const_for_snr);
end

%% Demodulate message from frame in frequency domain (block "Demodulator")
demodulated_messages_ZF = pskdemod(info_symbols_equalized_ZF(:), M, pi/4, OutputType="bit"); 
demodulated_messages_MMSE = pskdemod(info_symbols_equalized_MMSE(:), M, pi/4, OutputType="bit");

%% Decode by Viterbi-convolve hard
% parse messages
bits_ZF_in = demodulated_messages_ZF; %Complite_recive_bits(demodulated_messages_ZF, M);
bits_MMSE_in = demodulated_messages_MMSE;%Complite_recive_bits(demodulated_messages_MMSE, M);

% decode by Viterbi hard
bits_ZF = Decode_bits(bits_ZF_in, trellis, tbdepth, opmode, dectype);
bits_MMSE = Decode_bits(bits_MMSE_in, trellis, tbdepth, opmode, dectype);


%% Metrics calculation (blocks "BER" and "EVM")
[~, ber_ZF] = biterr(bits_out(:), bits_ZF);
[~, ber_MMSE] = biterr(bits_out(:), bits_MMSE);

evm_ZF = Compute_MSE(Mod_symbols, info_symbols_equalized_ZF);
evm_MMSE = Compute_MSE(Mod_symbols, info_symbols_equalized_MMSE);


result = [result; [ber_ZF, ber_MMSE, evm_ZF, evm_MMSE, SNR_dB]];
disp(SNR_dB);

end

fclose(fileID);
Plotting_result(result, result_names);
