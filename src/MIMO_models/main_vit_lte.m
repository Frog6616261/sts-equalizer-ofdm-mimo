clear all; close all; clc
%pkg load communications

%% parameters
rng(5); % random seed setter (for repeating the same results)

mod = 'QPSK';
M = 4; %for QPSK
numb_messages = 10000;
Nt = 2;
Nr = 2;
count_bits = numb_messages * Nt * log2(M); disp(count_bits);
SNR = -10:0.5:15;
plt_const_for_snr = 15;

result_names = ["BER ZF", "BER MMSE", "EVM ZF", "EVM MMSE", "SNR dB"];
result = [];


%% Open File
fileID = fopen('metrics.txt','w');
fprintf(fileID, '%s\t%s\t%s\t%s\t%s\n', "BER_ZF", "BER_MMSE", "EVM_ZF", "EVM_MMSE", "SNR_dB");


for SNR_dB = SNR

%% Generate LTE Messsage and References simbols
[bits_out, numb_bits] = Generate_messages_bits(Nt, numb_messages, M);
bits_lte = lteConvolutionalEncode(bits_out);
Mod_symbols = Complite_messages_for_LTE(Nt, bits_lte, mod);
pilots_simbols = Generate_pilots_symbols(Nt);


%% Channel fading and Antennas interfernce
%h = Generate_random_channel_matrix(Nt,Nr);
%h = eye(Nt);
h = [-2, 0.00001 + 1i; -0.00001, 1];
info_symbols_antenna_interference = h*Mod_symbols;
pilots_symbols_antenna_interference = h*pilots_simbols.';


%% Add the AWGN (block "AWGN")
info_symbols_out_channel = ADD_AWGN_MIMO(info_symbols_antenna_interference, SNR_dB);
pilots_symbols_out_channel = ADD_AWGN_MIMO(pilots_symbols_antenna_interference, SNR_dB);
 
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
demodulated_bits_ZF = Demodulate_messages_for_LTE(info_symbols_equalized_ZF, mod); 
demodulated_bits_MMSE = Demodulate_messages_for_LTE(info_symbols_equalized_MMSE, mod); 


%% Decode by Viterbi-convolve hard
bits_ZF = lteConvolutionalDecode(demodulated_bits_ZF)';
bits_MMSE = lteConvolutionalDecode(demodulated_bits_MMSE)';


%% Metrics calculation (blocks "BER" and "EVM")
ber_ZF = Compute_BER(bits_out, bits_ZF);
ber_MMSE = Compute_BER(bits_out, bits_MMSE);

evm_ZF = Compute_MSE(Mod_symbols, info_symbols_equalized_ZF);
evm_MMSE = Compute_MSE(Mod_symbols, info_symbols_equalized_MMSE);


fprintf(fileID, '%s\t%s\t%s\t%s\t%s\n', ber_ZF, ber_MMSE, evm_ZF, evm_MMSE, SNR_dB);
result = [result; [ber_ZF, ber_MMSE, evm_ZF, evm_MMSE, SNR_dB]];

disp(SNR_dB);

end

fclose(fileID);
Plotting_result(result, result_names);