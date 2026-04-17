clc; clear; close all;

%result = [SNR, BER];
result = [, ];
SNRs_dB = -2:0.5:7.5;
msg_len = 500000;   % Количество бит в сообщении
rng(1000);
M = 4;

for SNR_dB = SNRs_dB
    % Параметры
    constraint_length = 7; % Длина ограничения (Constraint Length)
    poly = [171 133]; % Полиномы кодера
    
    message = randi([0 1], msg_len, 1);
    
    trellis = poly2trellis(constraint_length, poly);
    coded_msg = convenc(message, trellis);
    
    coded_msg_qpsk = pskmod(coded_msg, M, pi/4, InputType="bit");
    noisy_signal = awgn(coded_msg_qpsk, SNR_dB, 'measured');
    demod_msg = pskdemod(noisy_signal, M, pi/4, OutputType="bit");
    
    tbdepth = 32;
    opmode = "trunc";
    dectype = "hard";
    decoded_msg = vitdec(demod_msg, trellis, tbdepth, opmode, dectype);
    
    num_errors = sum(decoded_msg(1:msg_len) ~= message);
    BER = num_errors / msg_len;
    result = [result; [SNR_dB, BER]];
    
    fprintf("BER = %.5f при SNR = %d дБ\n", BER, SNR_dB);
end

semilogy(result(:,1), result(:,2));
xlabel('SNR dB');  
ylabel('BER');  
title('BER HARD');
grid on;
