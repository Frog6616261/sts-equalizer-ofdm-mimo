clear all; close all; clc
%pkg load communications

%% Parameters
rng(11);

MIMO_LENGTH = 2:3; % 2:6

average_time_ML_algo = [];
average_time_STS_puring = [];
average_time_STS_backtrecking = [];

%% Create result directory
time_stamp_str = char(datetime('now'));
for i = 1:strlength(time_stamp_str)
    if (time_stamp_str(i) == '-' || time_stamp_str(i) == ':')
        time_stamp_str(i) = '.';
    end
end

folder = "results";
directory_for_results = folder + "\" + time_stamp_str + "_ml_sts_puring_backtrecking";

if ~exist(folder, "dir")
    mkdir(folder);
end
mkdir(directory_for_results);

for mimo_sz = MIMO_LENGTH

    %% Viterbi params
    n = 2; 
    k = 1; 
    L = 7;

    gen = [171 133];
    trellis = poly2trellis(L, gen);
    tblen = 35;
    tdhui = 'term';
    opmode = 'soft';

    %% MIMO params
    M = 16;
    numb_messages = 50;

    Nt = mimo_sz;
    Nr = mimo_sz;

    STEPS = 0:3;
    STEP_sz = 3;
    START_SNR = 4;
    SNR_arr = START_SNR + STEPS * STEP_sz;

    %% Results arrays
    Ber_ML_Max_Log = [];
    Ber_STS_puring = [];
    Ber_STS_backtrecking = [];

    time_ML_Max_Log = [];
    time_STS_puring = [];
    time_STS_backtrecking = [];

    clips_STS_puring = [];
    clips_STS_backtrecking = [];

    for CUR_STEP = STEPS

        SNR_dB = START_SNR + CUR_STEP * STEP_sz;

        %% Generate message and reference symbols
        enc = comm.ConvolutionalEncoder(trellis);

        [bits_out, numb_bits] = Generate_messages_bits(Nt, numb_messages, M);

        cod_vect = enc(bits_out(:));
        mod_vect = qammod(cod_vect(:), M, InputType="bit");
        Mod_symbols = reshape(mod_vect, Nt, []);

        %% Channel fading and antenna interference
        h = Generate_random_flat_fading_channel_matrix(Nt, Nr);
        H = h;

        info_symbols_antenna_interference = h * Mod_symbols;

        %% Add AWGN
        [info_symbols_out_channel, nVar] = ADD_AWGN_MIMO(info_symbols_antenna_interference, SNR_dB);

        %% Solve LLR: ML Max-Log
        tic;
        LLR_ML_Max_Log = Solve_LLR_ML(info_symbols_out_channel, M, H, nVar, @qammod, 'max-log');
        time_ML_Max_Log = [time_ML_Max_Log toc];

        %% Solve LLR: STS puring
        tic;
        [LLR_STS_puring, cur_clips_STS_puring] = Solve_LLR_STS(info_symbols_out_channel, M, H, nVar, @qammod, 'puring');
        time_STS_puring = [time_STS_puring toc];
        clips_STS_puring = [clips_STS_puring cur_clips_STS_puring];

        %% Solve LLR: STS backtrecking / purback
        tic;
        [LLR_STS_backtrecking, cur_clips_STS_backtrecking] = Solve_LLR_STS(info_symbols_out_channel, M, H, nVar, @qammod, 'purback');
        time_STS_backtrecking = [time_STS_backtrecking toc];
        clips_STS_backtrecking = [clips_STS_backtrecking cur_clips_STS_backtrecking];

        %% Viterbi decode
        vitDecUNQUANT = comm.ViterbiDecoder(trellis, ...
            'InputFormat', 'Unquantized', ...
            'TracebackDepth', tblen, ...
            'TerminationMethod', 'Truncated');

        Decode_Data_ML_Max_Log = vitDecUNQUANT(LLR_ML_Max_Log(:));
        Decode_Data_STS_puring = vitDecUNQUANT(LLR_STS_puring(:));
        Decode_Data_STS_backtrecking = vitDecUNQUANT(LLR_STS_backtrecking(:));

        %% Calculate BER
        [~, cur_ber_ML_algo] = biterr(bits_out(:), Decode_Data_ML_Max_Log(:));
        [~, cur_ber_STS_puring] = biterr(bits_out(:), Decode_Data_STS_puring(:));
        [~, cur_ber_STS_backtrecking] = biterr(bits_out(:), Decode_Data_STS_backtrecking(:));

        %% Write results
        Ber_ML_Max_Log = [Ber_ML_Max_Log cur_ber_ML_algo];
        Ber_STS_puring = [Ber_STS_puring cur_ber_STS_puring];
        Ber_STS_backtrecking = [Ber_STS_backtrecking cur_ber_STS_backtrecking];

        disp("mimo=" + string(mimo_sz) + ", SNR=" + string(SNR_dB) + " dB is done");
    end

    %% Replace zero BER values
    [SNR_ML_Max_Log, Ber_ML_Max_Log] = Replace_Zeros(SNR_arr, Ber_ML_Max_Log);
    [SNR_STS_puring, Ber_STS_puring] = Replace_Zeros(SNR_arr, Ber_STS_puring);
    [SNR_STS_backtrecking, Ber_STS_backtrecking] = Replace_Zeros(SNR_arr, Ber_STS_backtrecking);

    %% Names
    result_names = ["BER ML Max-Log", "BER STS puring", "BER STS backtrecking"];
    time_names = ["time ML Max-Log", "time STS puring", "time STS backtrecking"];
    clip_names = ["clips STS puring", "clips STS backtrecking"];

    %% Plot BER
    Plotting_multiple( ...
        {SNR_ML_Max_Log, SNR_STS_puring, SNR_STS_backtrecking}, ...
        {Ber_ML_Max_Log, Ber_STS_puring, Ber_STS_backtrecking}, ...
        result_names, ...
        "SNR dB", ...
        "BER", ...
        "result mimo=" + string(mimo_sz), ...
        1, ...
        directory_for_results);

    %% Plot execution time
    Plotting_multiple( ...
        {SNR_arr, SNR_arr, SNR_arr}, ...
        {time_ML_Max_Log, time_STS_puring, time_STS_backtrecking}, ...
        time_names, ...
        "SNR dB", ...
        "time sec", ...
        "Time compare mimo=" + string(mimo_sz), ...
        1, ...
        directory_for_results);

    %% Plot clips
    Plotting_multiple( ...
        {SNR_arr, SNR_arr}, ...
        {clips_STS_puring, clips_STS_backtrecking}, ...
        clip_names, ...
        "SNR dB", ...
        "numb clips", ...
        "Clip compare mimo=" + string(mimo_sz), ...
        1, ...
        directory_for_results);

    %% Save average time for current MIMO
    average_time_ML_algo = [average_time_ML_algo mean(time_ML_Max_Log)];
    average_time_STS_puring = [average_time_STS_puring mean(time_STS_puring)];
    average_time_STS_backtrecking = [average_time_STS_backtrecking mean(time_STS_backtrecking)];

    disp("mimo=" + string(mimo_sz) + " is done");
end

%% Average time over MIMO size
average_time_names = ["time ML Max-Log", "time STS puring", "time STS backtrecking"];

Plotting_multiple( ...
    {MIMO_LENGTH, MIMO_LENGTH, MIMO_LENGTH}, ...
    {average_time_ML_algo, average_time_STS_puring, average_time_STS_backtrecking}, ...
    average_time_names, ...
    "MIMO sz", ...
    "time sec", ...
    "AVERAGE Time compare", ...
    1, ...
    directory_for_results);