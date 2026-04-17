function message = decode_frame(frame, M)

%% demodulation
message = qamdemod(frame, M);

end

% 29.03.24
% reduced to simple demodulator
