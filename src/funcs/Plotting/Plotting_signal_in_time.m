function Plotting_signal_in_time(QAM_simbol, carrying_frequency, time)

% Параметры QAM
N = 1000;
fc = carrying_frequency; % Несущая частота 

% Временной вектор
t = linspace(0, time, N);

% Перенос на несущую частоту
qam_carrier = real(QAM_simbol .* exp(1j*2*pi*fc*t'));

% Визуализация сигнала без фильтрации
figure;
plot(t, qam_carrier);
title('QAM-сигнал на несущей частоте');
xlabel('Time (s)'); ylabel('Amplitude'); grid on;
legend('Real Part', 'Imaginary Part');


end