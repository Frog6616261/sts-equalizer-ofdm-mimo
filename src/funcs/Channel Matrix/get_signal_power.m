function E = get_signal_power(signal)
% calculates the power of discrete signal
% Inputs:       signal  : Signal in time/frequency domain

% Output:       E : signal power
signal = signal(:);
E = (signal'*signal) / length(signal);
end
