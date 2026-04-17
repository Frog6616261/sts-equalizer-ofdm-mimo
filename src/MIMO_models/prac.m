clear all; close all; clc
%pkg load communications
addpath("funcs\Max-Log-MAP\");
RTS.Solve_LLR();
%% parameters
rng(5); % random seed setter (for repeating the same results)

% viterbi params
n=2;k=1;L=7;
gen=[171 133];
trellis = poly2trellis(L,gen);
tblen=6;
tdhui = 'term';
opmode ='soft';


M = power(2,4); % e.g. 2, 4, 8 -> PSK; 16, 64... -> QAM
size_bits = log2(M);
numb_messages = 500;
Nt = 2;Nr = 2;
SNRs = 2:1:12 ;

% result = ["BER_ZF", "BER_MMSE", "EVM_ZF", "EVM_MMSE", "SNR_dB"];
result = [];

%% Open File
fileID = fopen('metrics.txt','w');
fprintf(fileID, '%s\t%s\t%s\t%s\t%s\n', "BER_ZF", "BER_MMSE", "EVM_ZF", "EVM_MMSE", "SNR_dB");


for SNR_dB = SNRs


%% Generate Messsage and References simbols
enc = comm.ConvolutionalEncoder(trellis);
[bits_out, numb_bits] = Generate_messages_bits(Nt, numb_messages, M);
cod_vect = enc(bits_out(:));
mod_vect = qammod(cod_vect(:), M, InputType="bit");
Mod_symbols = reshape(mod_vect, Nt, []);
pilots_simbols = Generate_pilots_symbols(Nt);

%Plotting_QAM_symbols(mod_vect, false);


%% Channel fading and Antennas interfernce
h = Generate_random_channel_matrix(Nt,Nr);
%h = eye(Nt);
%h = [-2, 0.00001+1i ; -0.00001, 1];
H = h;
info_symbols_antenna_interference = h*Mod_symbols;
pilots_symbols_antenna_interference = h*pilots_simbols.';


%% Add the AWGN (block "AWGN")
[info_symbols_out_channel, nVar] = ADD_AWGN_MIMO(info_symbols_antenna_interference, SNR_dB);
[pilots_symbols_out_channel, ~] = ADD_AWGN_MIMO(pilots_symbols_antenna_interference, SNR_dB);

info_symbols_equalized_ZF = reshape(use_ZF_equalizer(info_symbols_out_channel, H, Nt), [], 1);
info_symbols_equalized_MMSE = reshape(use_my_MMSE_equalizer(info_symbols_out_channel, H, Nr, Nt, SNR_dB, 0), [], 1);
info_synb_SD = reshape(SD_message(H,info_symbols_out_channel,M),[],1);


%% Solve LLR
LL_SD = qamdemod(info_synb_SD, M, OutputType="llr");
LL_intern_ZF = qamdemod(info_symbols_equalized_ZF, M, OutputType="llr");
LL_intern_MMSE = qamdemod(info_symbols_equalized_MMSE, M, OutputType="llr");
LLR_ML= Solve_LLR_ML(info_symbols_out_channel, M, H, nVar, SNR_dB);
LLR_SDS = LLSD_mes_list(info_symbols_out_channel, H, M, SNR_dB);


%% Viterbi-Decode message
vitDecUNQUANT = comm.ViterbiDecoder(trellis, ...
    'InputFormat','Unquantized', ...
    'TracebackDepth', tblen); 


Decode_Data_SD = vitDecUNQUANT(LL_SD);
Decode_Data_ZF_int = vitDecUNQUANT(LL_intern_ZF);
Decode_Data_MMSE_int = vitDecUNQUANT(LL_intern_MMSE); 
Decode_Data_ML = vitDecUNQUANT(LLR_ML);
Decode_Data_SDS = vitDecUNQUANT(LLR_SDS);


%% Calculate metrics
[~, ber_SD] = biterr(transpose(bits_out(1:end-tblen)), Decode_Data_SD(tblen+1:end));
[~, ber_ZF_int] = biterr(transpose(bits_out(1:end-tblen)), Decode_Data_ZF_int(tblen+1:end));
[~, ber_MMSE_int] = biterr(transpose(bits_out(1:end-tblen)), Decode_Data_MMSE_int(tblen+1:end));
[~, ber_ML] = biterr(transpose(bits_out(1:end-tblen)), Decode_Data_ML(tblen+1:end));
[~, ber_SDS] = biterr(transpose(bits_out(1:end-tblen)), Decode_Data_SDS(tblen+1:end));


result = [result;[ber_SD,ber_ZF_int,ber_MMSE_int,ber_ML,ber_SDS,SNR_dB]];
disp(SNR_dB)
end
figure;
semilogy(result(:,6),result(:,1),result(:,6),result(:,2),result(:,6),result(:,3),result(:,6),result(:,4), result(:,6),result(:,5));
title('Comparison of BER for internal func and custom QAM - 16 ')
legend("BER Hard-SD", "BER ZF", "BER MMSE", "BER ML", "BER Soft-SD")

figure;
RTS.Solve_LLR();

histogram(LLR_SDS)
hold on;
histogram(LLR_ML)
hold off;
title('LLR comparison')
legend('SD - soft','ML')