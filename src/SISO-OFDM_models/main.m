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
L=7;
gen=[171 133];
conv_code_coef = length(gen);
trellis = poly2trellis(L,gen);
tblen=35;
tdhui = 'term';
opmode ='soft';

% frequency band params

% values from IEEE LTE 30.72 MHz band
Bw = 30.72e6; % Hz -- Bandwidth
delta_f = 15e3;
N_FFT = 2048; %int(Bw/delta_f);
N_used = 1201;
Ts = 1/(delta_f); 
delta_t = 1/Bw; 
guard_bands = get_guard_band_samples(N_FFT, N_used);
[N_used_start.start, N_used_start.end] = get_num_of_start_used_carrier(N_FFT, N_used);
[N_used_end.start, N_used_end.end] = get_num_of_end_used_carrier(N_FFT, N_used);


cp_length = 160; %idivide(time_cp, delta_t);

N = N_FFT + cp_length;


M = 16; % e.g. 2, 4, 8 -> PSK; 16, 64... -> QAM
N_bits_in_mod = log2(M);
numb_frames = 10;
STEPS = 0:7;
STEP_sz = 2;
START_SNR = 1;
SNRs = START_SNR + STEPS*STEP_sz;

N_bits_for_frame = N_used * N_bits_in_mod / conv_code_coef;

Ber = [];


for CUR_STEP = STEPS

SNR_dB = START_SNR + CUR_STEP*STEP_sz;

Decode_Data = [];
info_bits_out = [];

for num_frame = 1:numb_frames

%% Generate Messsage bits like packeges
[cur_info_bits_out, info_numb_bits] = Generate_sequence_of_bits(N_bits_for_frame);


%% Coded by convolution code
enc = comm.ConvolutionalEncoder(trellis);
cod_vecotrs = enc(cur_info_bits_out);
coded_bits = cod_vecotrs(:);


%% Mapping
FFT_coefs_for_messages = qammod(coded_bits, M, 'InputType','bit');
FFT_coefs_for_messages = FFT_coefs_for_messages(:).'; 


%% Time coefs
info_frame_tx_fd = zeros(1, N_FFT);
info_frame_tx_td = zeros(1, N_FFT);

info_frame_fd_i = zeros(1, N_FFT);
info_frame_fd_i([N_used_start.start:N_used_start.end N_used_end.start:N_used_end.end]) = ...
    FFT_coefs_for_messages(1, :);
info_frame_tx_fd(1, :) = info_frame_fd_i;
info_frame_tx_td(1, :) = ifft(info_frame_fd_i);


%% Add cyclic prefix
info_frame_out = zeros(1, N_FFT + cp_length);

info_frame_out(1, :) = add_cyclic_prefix(info_frame_tx_td(1, :), cp_length);


%% Add the AWGN (block "AWGN")
[info_frame_out_channel, nVar_info] = ADD_AWGN_MIMO(info_frame_out, SNR_dB);


%% Remove cyclic prefix
info_frame_out_channel_without_cp = zeros(1, N_FFT);

info_frame_out_channel_without_cp(1, :) = ...
    remove_cyclic_prefix(info_frame_out_channel(1, :), cp_length);


%% FFT
info_frame_rx_fd = zeros(1, N_FFT);

info_frame_rx_fd(1, :) = fft(info_frame_out_channel_without_cp(1, :));


%% Demapping
% bits_rx = [];
% for id_fd = N_used_start.start:N_used_start.end
%     bits_id = qamdemod(info_frame_rx_fd(1, id_fd), M, OutputType="bit");
%     bits_rx = [bits_rx bits_id(:).'];    
% end
% 
% for id_fd = N_used_end.start:N_used_end.end
%     bits_id = qamdemod(info_frame_rx_fd(1, id_fd), M, OutputType="bit");
%     bits_rx = [bits_rx bits_id(:).'];    
% end

LLR = [];
for id_fd = N_used_start.start:N_used_start.end
    llr_id = qamdemod(info_frame_rx_fd(1, id_fd), M, OutputType="llr");
    LLR = [LLR llr_id(:).'];    
end

for id_fd = N_used_end.start:N_used_end.end
    llr_id = qamdemod(info_frame_rx_fd(1, id_fd), M, OutputType="llr");
    LLR = [LLR llr_id(:).'];    
end


%% Viterbi-Decode message
vitDecUNQUANT = comm.ViterbiDecoder(trellis, ...
    'InputFormat','Unquantized', ...
    'TracebackDepth', tblen, 'TerminationMethod','Truncated'); 

cur_Decode_Data = vitDecUNQUANT(LLR(:));

%% Calculate awerage signal power
avg_signal_tx_power = get_signal_power(info_frame_tx_fd);
avg_signal_rx_power = get_signal_power(info_frame_rx_fd);

if (num_frame == 1)
    disp("snr="+ string(SNR_dB) +"  avg_pow_tx=" + string(avg_signal_tx_power) + "  avg_pow_rx=" + string(avg_signal_rx_power));
end
%% Write results
% Decode_Data = [Decode_Data bits_rx(:).'];
Decode_Data = [Decode_Data cur_Decode_Data(:).'];
info_bits_out = [info_bits_out cur_info_bits_out(:).'];
end


%% Calculate metrics
[~, ber] = biterr(info_bits_out(:), Decode_Data(:));


%% Write results
Ber = [Ber ber];


% %% Plotting QAM symbols
% Plotting_QAM_symbols(info_frame_tx_fd([N_used_start.start:N_used_start.end N_used_end.start:N_used_end.end]), 0);
% Plotting_QAM_symbols(info_frame_rx_fd([N_used_start.start:N_used_start.end N_used_end.start:N_used_end.end]), 1);

disp(SNR_dB)
end


%% Plotting results

% replase zeros ber
[SNR_result, Ber] = Replace_Zeros(SNRs, Ber);

% plotting ber
Plotting_multiple({SNR_result}, {Ber}, ["Ber in AWGN"], "SNR dB", "BER", "result", 1, directory_for_results);





