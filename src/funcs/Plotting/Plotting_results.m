function Plotting_results(results)
SNRs = results.snr;

Ber_ZF = results.ZF.ber;
time_ZF = results.ZF.time; 

Ber_MMSE = results.MMSE.ber;
time_MMSE = results.MMSE.time; 

Ber_ML = results.ML.ber;
time_ML = results.ML.time;

Ber_STS = results.STS.ber;
time_STS = results.STS.time;
clips_STS = results.STS.clips;

result_names = ["ZF", "MMSE", "ML", "STS"];
time_names = ["ZF", "MMSE", "ML", "STS"];
clip_names = ["STS"];


% replase zeros ber
[SNR_ZF, Ber_ZF] = Replace_Zeros(SNRs, Ber_ZF);
[SNR_MMSE, Ber_MMSE] = Replace_Zeros(SNRs, Ber_MMSE);
[SNR_ML, Ber_ML] = Replace_Zeros(SNRs, Ber_ML);
[SNR_STS, Ber_STS] = Replace_Zeros(SNRs, Ber_STS);
 

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


% plotting ber
Plotting_multiple({SNR_ZF, SNR_MMSE, SNR_ML, SNR_STS}, {Ber_ZF, Ber_MMSE, Ber_ML, Ber_STS}, result_names, "SNR dB", "BER", "result", 1, directory_for_results);

% plotting execution time curves
Plotting_multiple({SNRs, SNRs, SNRs, SNRs}, {time_ZF, time_MMSE, time_ML, time_STS}, time_names, "SNR dB", "time sec", "Time compare", 1, directory_for_results);

% plotting curves of numb clips
Plotting_multiple({SNRs}, {clips_STS}, clip_names, "SNR dB", "numb clips", "Clip compare", 1, directory_for_results);

end

