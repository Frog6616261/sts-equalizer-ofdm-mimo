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


% turbocode params
L=7;
gen=[171 133];
conv_code_coef = length(gen);
trellis = poly2trellis(L, gen, 171);
tblen=35;
tdhui = 'term';
opmode ='soft';


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
numb_frames = 1;
Nt = 2; Nr = 2;
STEPS = 0:5;
STEP_sz = 2;
START_SNR = 9;
SNRs = START_SNR + STEPS*STEP_sz;

N_bits_for_frame = Nt * N_used * N_bits_in_mod / conv_code_coef;

% channel params
path_delay = [1  30 70 90 110 190 410];
path_gain_db = [0 -1 -2 -3 -8 -17.2 -20.8];

K = N_bits_for_frame;                         % number of information bits (choose any)
intrlvrInd = randperm(K).';       % interleaver indices (column), length K

% constant channel for each frame
h = get_MIMO_Rayleigh_channel(path_delay, path_gain_db, Nr, Nt);

Plotting_and_save_MIMO_Channel_matrix(h, "channel_matrix_maxt1_R1_09_complex", directory_for_results);



Evm_ZF = [];
Evm_MMSE = [];

Ber_ZF = [];
Ber_MMSE = [];
Ber_ML = [];
Ber_STS = [];

time_ZF = [];
time_MMSE = [];
time_ML = [];
time_STS = [];

clips_STS = [];


for CUR_STEP = STEPS

SNR_dB = START_SNR + CUR_STEP*STEP_sz;

Output_signals = [];
Decode_signals_ZF = [];
Decode_signals_MMSE = [];

Decode_Data_ZF = [];
Decode_Data_MMSE = [];
Decode_Data_ML = [];
Decode_Data_STS = [];
info_bits_out = [];

cur_time_ZF = [];
cur_time_MMSE = [];
cur_time_ML = [];
cur_time_STS = [];

cur_clips_STS = [];

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


%% Serial to paralel for antennas
FFT_coefs_for_message_antennas = reshape(FFT_coefs_for_messages, Nt, []);
FFT_pilot_coefs_for_message_antennas = get_pilot_coefs(Nt, Nr, N_used);

Output_signals = [Output_signals FFT_coefs_for_message_antennas];


%% Time coefs
info_frame_tx_fd = zeros(Nt, N_FFT);
info_frame_tx_td = zeros(Nt, N_FFT);


for i = 1:Nt
    info_frame_fd_i = zeros(1, N_FFT);
    info_frame_fd_i([N_used_start.start:N_used_start.end N_used_end.start:N_used_end.end]) = ...
        FFT_coefs_for_message_antennas(i, :);
    info_frame_tx_fd(i, :) = info_frame_fd_i;
    info_frame_tx_td(i, :) = ifft(info_frame_fd_i).*sqrt(N_FFT);
end


%% Add cyclic prefix
info_frame_out = zeros(Nt, N_FFT + cp_length);

for i = 1:Nt
    info_frame_out(i, :) = add_cyclic_prefix(info_frame_tx_td(i, :), cp_length);
end


%% Channel fading and Antennas interfernce

% Convolution
info_frame_conv = MIMO_convolution(info_frame_out, h, N_FFT, cp_length);


%% Add the AWGN (block "AWGN")
[info_frame_out_channel, nVar_info] = ADD_AWGN_MIMO(info_frame_conv, SNR_dB);


%% Remove cyclic prefix
info_frame_out_channel_without_cp = zeros(Nr, N_FFT);

for i = 1:Nr
    info_frame_out_channel_without_cp(i, :) = ...
        remove_cyclic_prefix(info_frame_out_channel(i, :), cp_length);
end


%% FFT
info_frame_rx_fd = zeros(Nr, N_FFT);

for i = 1:Nr
    info_frame_rx_fd(i, :) = fft(info_frame_out_channel_without_cp(i, :))./sqrt(N_FFT);
end


%% Find channel matrix
H_fd_fft = get_channel_matrix_by_fft(h, N_FFT);


%% Equalizers by channel matrix

% Zero-Forcing
cur_time = 0;
LLR_ZF = [];
for id_fd = N_used_start.start:N_used_start.end
    H = H_fd_fft(:, :, id_fd);
    tic;
    equalize_symb_id = use_ZF_equalizer(info_frame_rx_fd(:, id_fd), H, Nt);
    llr_id = qamdemod(equalize_symb_id, M, OutputType="llr");
    cur_time = cur_time + toc;
    Decode_signals_ZF = [Decode_signals_ZF equalize_symb_id];
    LLR_ZF = [LLR_ZF llr_id(:).'];    
end
for id_fd = N_used_end.start:N_used_end.end
    H = H_fd_fft(:, :, id_fd);
    tic;
    equalize_symb_id = use_ZF_equalizer(info_frame_rx_fd(:, id_fd), H, Nt);
    llr_id = qamdemod(equalize_symb_id, M, OutputType="llr");
    cur_time = cur_time + toc;
    Decode_signals_ZF = [Decode_signals_ZF equalize_symb_id];
    LLR_ZF = [LLR_ZF llr_id(:).'];    
end

cur_time_ZF = [cur_time_ZF cur_time];


% MMSE
cur_time = 0;
LLR_MMSE = [];
for id_fd = N_used_start.start:N_used_start.end
    H = H_fd_fft(:, :, id_fd);
    tic;
    equalize_symb_id = use_MMSE_equalizer(info_frame_rx_fd(:, id_fd), H, Nr, Nt, SNR_dB, 0);
    llr_id = qamdemod(equalize_symb_id, M, OutputType="llr");
    cur_time = cur_time + toc;
    Decode_signals_MMSE = [Decode_signals_MMSE equalize_symb_id];
    LLR_MMSE = [LLR_MMSE llr_id(:).'];    
end
for id_fd = N_used_end.start:N_used_end.end
    H = H_fd_fft(:, :, id_fd);
    tic;
    equalize_symb_id = use_MMSE_equalizer(info_frame_rx_fd(:, id_fd), H, Nr, Nt, SNR_dB, 0);
    llr_id = qamdemod(equalize_symb_id, M, OutputType="llr");
    cur_time = cur_time + toc;
    Decode_signals_MMSE = [Decode_signals_MMSE equalize_symb_id];
    LLR_MMSE = [LLR_MMSE llr_id(:).'];    
end

cur_time_MMSE = [cur_time_MMSE cur_time];


%% Equalizers ML algorithms
% ML
cur_time = 0;
LLR_ML = [];
for id_fd = N_used_start.start:N_used_start.end
    H = H_fd_fft(:, :, id_fd);
    tic;
    [llr_id, ~] = Solve_LLR_ML_algo(info_frame_rx_fd(:, id_fd), M, H, nVar_info, @qammod);
    cur_time = cur_time + toc;
    LLR_ML = [LLR_ML llr_id(:).'];    
end
for id_fd = N_used_end.start:N_used_end.end
    H = H_fd_fft(:, :, id_fd);
    tic;
    [llr_id, ~] = Solve_LLR_ML_algo(info_frame_rx_fd(:, id_fd), M, H, nVar_info, @qammod);
    cur_time = cur_time + toc;
    LLR_ML = [LLR_ML llr_id(:).'];    
end

cur_time_ML = [cur_time_ML cur_time];


%% Equalizers MAP algorithms
% STS
cur_time = 0;
cur_clips = 0;
LLR_STS = [];
for id_fd = N_used_start.start:N_used_start.end
    H = H_fd_fft(:, :, id_fd);
    tic;
    [llr_id, clips_id] = Solve_LLR_STS(info_frame_rx_fd(:, id_fd), M, H, nVar_info, @qammod);
    cur_time = cur_time + toc;
    cur_clips = cur_clips + clips_id;
    LLR_STS = [LLR_STS llr_id(:).'];    
end

for id_fd = N_used_end.start:N_used_end.end
    H = H_fd_fft(:, :, id_fd);
    tic;
    [llr_id, clips_id] = Solve_LLR_STS(info_frame_rx_fd(:, id_fd), M, H, nVar_info, @qammod);
    cur_time = cur_time + toc;
    cur_clips = cur_clips + clips_id;
    LLR_STS = [LLR_STS llr_id(:).'];    
end

cur_time_STS = [cur_time_STS cur_time];
cur_clips_STS = [cur_clips_STS cur_clips];


%% Viterbi-Decode message
vitDecUNQUANT = comm.ViterbiDecoder(trellis, ...
    'InputFormat','Unquantized', ...
    'TracebackDepth', tblen, 'TerminationMethod','Truncated'); 

cur_Decode_Data_ZF = vitDecUNQUANT(LLR_ZF(:));
cur_Decode_Data_MMSE = vitDecUNQUANT(LLR_MMSE(:));
cur_Decode_Data_ML = vitDecUNQUANT(LLR_ML(:));
cur_Decode_Data_STS = vitDecUNQUANT(LLR_STS(:));


%% Write results
Decode_Data_ZF = [Decode_Data_ZF cur_Decode_Data_ZF.'];
Decode_Data_MMSE = [Decode_Data_MMSE cur_Decode_Data_MMSE.'];
Decode_Data_ML = [Decode_Data_ML cur_Decode_Data_ML.'];
Decode_Data_STS = [Decode_Data_STS cur_Decode_Data_STS.'];
info_bits_out = [info_bits_out cur_info_bits_out.'];



%% Calculate awerage signal power
avg_signal_tx_fd_power = get_signal_power(info_frame_tx_fd);
avg_signal_rx_fd_power = get_signal_power(info_frame_rx_fd);

avg_signal_tx_td_power = get_signal_power(info_frame_tx_td);
avg_signal_rx_td_power = get_signal_power(info_frame_out_channel_without_cp);

disp("snr="+ string(SNR_dB)+"  num_frame="+string(num_frame));
disp("avg_pow_tx_fd=" + string(avg_signal_tx_fd_power) + "  avg_pow_rx_fd=" + string(avg_signal_rx_fd_power));
disp("avg_pow_tx_td=" + string(avg_signal_tx_td_power) + "  avg_pow_rx_td=" + string(avg_signal_rx_td_power));
end


%% Calculate metrics
[~, ber_ZF] = biterr(info_bits_out(:), Decode_Data_ZF(:));
[~, ber_MMSE] = biterr(info_bits_out(:), Decode_Data_MMSE(:));
[~, cur_ber_ML] = biterr(info_bits_out(:), Decode_Data_ML(:));
[~, cur_ber_STS] = biterr(info_bits_out(:), Decode_Data_STS(:));

evm_ZF = Compute_MSE(Output_signals, Decode_signals_ZF);
evm_MMSE = Compute_MSE(Output_signals, Decode_signals_MMSE);


%% Write results
Ber_ZF = [Ber_ZF ber_ZF];
Ber_MMSE = [Ber_MMSE ber_MMSE];
Ber_ML = [Ber_ML cur_ber_ML];
Ber_STS = [Ber_STS cur_ber_STS];

Evm_ZF = [Evm_ZF evm_ZF];
Evm_MMSE = [Evm_MMSE evm_MMSE];

time_ZF = [time_ZF sum(cur_time_ZF)];
time_MMSE = [time_MMSE sum(cur_time_MMSE)];
time_ML = [time_ML sum(cur_time_ML)];
time_STS = [time_STS sum(cur_time_STS)];

clips_STS = [clips_STS sum(cur_clips_STS)];


%% Plotting Constellations
Plotting_and_save_constellations(FFT_coefs_for_messages, FFT_coefs_for_messages, info_frame_rx_fd, ...
    Decode_signals_ZF, SNR_dB, 0, 0, 1, "ZF", directory_for_results);

Plotting_and_save_constellations(FFT_coefs_for_messages, FFT_coefs_for_messages, info_frame_rx_fd, ...
    Decode_signals_MMSE, SNR_dB, 0, 0, 1, "MMSE", directory_for_results);


disp(SNR_dB)
end


%% Plotting results
ber_names = ["ZF", "MMSE", "ML", "STS"];
evm_names = ["ZF", "MMSE"];
time_names = ["ZF", "MMSE", "ML", "STS"];
clip_names = ["STS"];


% replase zeros ber
[SNR_ZF, Ber_ZF] = Replace_Zeros(SNRs, Ber_ZF);
[SNR_MMSE, Ber_MMSE] = Replace_Zeros(SNRs, Ber_MMSE);
[SNR_ML, Ber_ML] = Replace_Zeros(SNRs, Ber_ML);
[SNR_STS, Ber_STS] = Replace_Zeros(SNRs, Ber_STS);
 

% plotting ber
Plotting_multiple({SNR_ZF, SNR_MMSE, SNR_ML, SNR_STS}, {Ber_ZF, Ber_MMSE, Ber_ML, Ber_STS}, ber_names, "SNR dB", "BER", "Ber compare", 1, directory_for_results);

% plotting evm
Plotting_multiple({SNRs; SNRs}, {Evm_ZF; Evm_MMSE}, evm_names, "SNR", "EVM", "Evm compare", 1, directory_for_results);

% plotting execution time curves
Plotting_multiple({SNRs, SNRs, SNRs, SNRs}, {time_ZF, time_MMSE, time_ML, time_STS}, time_names, "SNR dB", "time sec", "Time compare", 1, directory_for_results);

% plotting curves of numb clips
Plotting_multiple({SNRs}, {clips_STS}, clip_names, "SNR dB", "numb clips", "Clip compare", 1, directory_for_results);
