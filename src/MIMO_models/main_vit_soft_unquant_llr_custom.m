clear all; close all; clc

%% parameters
rng(5); % random seed setter (for repeating the same results)

% viterbi params
n=2;k=1;L=7;
gen=[171 133];
trellis = poly2trellis(L,gen);
tblen=5*(k);
tdhui = 'term';
opmode ='soft';


M = 4; % QAM16
size_bits = log2(M);
numb_messages = 5000;
Nt = 2;Nr = 2;
SNRs = -2:1:30;
plt_const_for_snr = 25;

result_names = ["BER ZF", "BER MMSE", "EVM ZF", "EVM MMSE", "SNR dB"];
result = [];


for SNR_dB = SNRs
%% Generate Messsage and References simbols
enc = comm.ConvolutionalEncoder(trellis);
[bits_out, numb_bits] = Generate_messages_bits(Nt, numb_messages, M);
cod_vect = enc(bits_out(:));
mod_vect = qammod(cod_vect(:), M, InputType="bit");
Mod_symbols = reshape(mod_vect, Nt, []);
pilots_simbols = Generate_pilots_symbols(Nt);


%% Channel fading and Antennas interfernce
h = Generate_random_channel_matrix(Nt,Nr);
%h = eye(Nt);
%h = [-2, 0.00001 + 1i; -0.00001, 1];

info_symbols_antenna_interference = h*Mod_symbols;
pilots_symbols_antenna_interference = h*pilots_simbols.';

if SNR_dB == plt_const_for_snr
    Plotting_QAM_symbols(info_symbols_antenna_interference, false);
end


%% Add the AWGN (block "AWGN")
[info_symbols_out_channel, nVar] = ADD_AWGN_MIMO(info_symbols_antenna_interference, SNR_dB);
[pilots_symbols_out_channel, nVar] = ADD_AWGN_MIMO(pilots_symbols_antenna_interference, SNR_dB);
 
if SNR_dB == plt_const_for_snr
    Plotting_QAM_symbols(info_symbols_out_channel, true);
end


%% Equalizer training and using
%H = Find_channel_matrix(pilots_symbols_out_channel, pilots_simbols);
H = h;

info_symbols_equalized_ZF = reshape(use_ZF_equalizer(info_symbols_out_channel, H, Nt), [], 1);
info_symbols_equalized_MMSE = reshape(use_my_MMSE_equalizer(info_symbols_out_channel, H, Nr, Nt, SNR_dB, 0), [], 1);

if SNR_dB == plt_const_for_snr
    Plotting_QAM_symbols_for_equalasers( ...
        info_symbols_equalized_ZF, info_symbols_equalized_MMSE, plt_const_for_snr);
end


%% Demodulate message from frame in frequency domain (block "Demodulator")
[QAM_REC_Data_ZF, ~] = LLR_custom(info_symbols_equalized_ZF, M, nVar);
[QAM_REC_Data_MMSE, ~] = LLR_custom(info_symbols_equalized_MMSE, M, nVar);


%% Decode by Viterbi soft
traice_depth = 32;
vitDecUNQUANT = comm.ViterbiDecoder(trellis, ...
    'InputFormat','Unquantized', ...
    'TracebackDepth', traice_depth); 

Decode_Data_ZF = vitDecUNQUANT(QAM_REC_Data_ZF(:));

vitDecUNQUANT = comm.ViterbiDecoder(trellis, ...
    'InputFormat','Unquantized', ...
    'TracebackDepth', traice_depth); 

Decode_Data_MMSE = vitDecUNQUANT(QAM_REC_Data_MMSE(:));


%% Metrics calculation (blocks "BER" and "EVM")
res_bits_out = bits_out(:);
[~, ber_ZF] = biterr(res_bits_out(1:end-traice_depth), Decode_Data_ZF(traice_depth+1:end));
[~, ber_MMSE] = biterr(res_bits_out(1:end-traice_depth), Decode_Data_MMSE(traice_depth+1:end));
evm_ZF = Compute_MSE(mod_vect, info_symbols_equalized_ZF(:));
evm_MMSE = Compute_MSE(mod_vect, info_symbols_equalized_MMSE(:));


%% Fill result
result = [result; [ber_ZF, ber_MMSE, evm_ZF, evm_MMSE, SNR_dB]];
disp(SNR_dB);
reset(enc)
reset(vitDecUNQUANT)
end


Plotting_result(result, result_names);