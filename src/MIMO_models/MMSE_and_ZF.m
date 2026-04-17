clear all; close all; clc

%% parameters
rng(5); 


M = 16; % e.g. 2, 4, 8 -> PSK; 16, 64... -> QAM
numb_messages = 20000;
Nt = 3; Nr = 3;
SNRs = 10:2:22;
N_bits_for_frame = log2(M) * numb_messages * Nt;


ber_names = ["BER ZF", "BER MMSE"];

Ber_ZF = [];
Ber_MMSE = [];


evm_names = ["EVM ZF", "EVM MMSE"];

Evm_ZF = [];
Evm_MMSE = [];

%% Main loop
for SNR_dB = SNRs

    
%% Generate Messsage and References simbols
[bits_out, numb_bits] = Generate_sequence_of_bits(N_bits_for_frame);


%% Mapping
mod_vect = qammod(bits_out(:), M, InputType="bit");


%% Serial to parralel
info_frame_tx_fd = reshape(mod_vect, Nt, []);


%% Channel fading and Antennas interfernce
h = Generate_random_channel_matrix(Nt,Nr);
% h = Generate_random_flat_fading_channel_matrix(Nt, Nr);
% h = [1 0 0; 0 1 0; 0 0 1];
% h = Generate_random_channel_matrix_notHermitian(Nr, Nt, 0.0001, 2);
% Test_channel_matrix(h, M);

info_frame_conv = h*info_frame_tx_fd;

disp("snr_db=" + string(SNR_dB) + "  cond(h)=" + string(cond(h)));


%% Add the AWGN (block "AWGN")
info_frame_out_channel = ADD_AWGN_MIMO(info_frame_conv, SNR_dB);


%% Use ZF and MMSE Equalizers
H = h;

info_frame_equalized_ZF = use_ZF_equalizer(info_frame_out_channel, h, Nt);
info_frame_equalized_MMSE = use_MMSE_equalizer(info_frame_out_channel, h, Nr, Nt, SNR_dB, 0);


%% Demapping
bits_ZF = qamdemod(info_frame_equalized_ZF(:), M, OutputType="bit"); 
bits_MMSE = qamdemod(info_frame_equalized_MMSE(:), M, OutputType="bit");


%% Metrics calculation (blocks "BER" and "EVM")
[~, ber_ZF] = biterr(bits_out, bits_ZF);
[~, ber_MMSE] = biterr(bits_out, bits_MMSE);
evm_ZF = Compute_MSE(info_frame_tx_fd, info_frame_equalized_ZF);
evm_MMSE = Compute_MSE(info_frame_tx_fd, info_frame_equalized_MMSE);


Ber_ZF = [Ber_ZF, ber_ZF];
Ber_MMSE = [Ber_MMSE, ber_MMSE];

Evm_ZF = [Evm_ZF evm_ZF];
Evm_MMSE = [Evm_MMSE evm_MMSE];


%% Plotting QAM symbols
Plotting_constellations(info_frame_tx_fd, info_frame_conv, info_frame_out_channel, ...
    info_frame_equalized_ZF, SNR_dB, 0, 0, 1);

Plotting_constellations(info_frame_tx_fd, info_frame_conv, info_frame_out_channel, ...
    info_frame_equalized_MMSE, SNR_dB, 0, 0, 1);


%% Calculate awerage signal power
avg_signal_tx_power = get_signal_power(info_frame_tx_fd);
avg_signal_rx_power = get_signal_power(info_frame_out_channel);

disp("snr="+ string(SNR_dB) +"  avg_pow_tx=" + string(avg_signal_tx_power) + "  avg_pow_rx=" + string(avg_signal_rx_power));


disp(SNR_dB);
end

% replase zeros ber
[SNR_ZF, Ber_ZF] = Replace_Zeros(SNRs, Ber_ZF);
[SNR_MMSE, Ber_MMSE] = Replace_Zeros(SNRs, Ber_MMSE);


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


Plotting_multiple({SNR_ZF; SNR_MMSE}, {Ber_ZF; Ber_MMSE}, ber_names, "SNR", "BER", "Results", 1, directory_for_results);

Plotting_multiple({SNRs; SNRs}, {Evm_ZF; Evm_MMSE}, evm_names, "SNR", "EVM", "Results", 1, directory_for_results);



