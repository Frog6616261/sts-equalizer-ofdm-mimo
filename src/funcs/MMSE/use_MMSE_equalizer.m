function output = use_MMSE_equalizer(symbols_in, H, Nr, Nt, snr_db, relative_snr_error)
% 1D MMSE equalizer x = 1/(h+1/(h'*SNR))*y
% Inputs:       
%               snr_db          : snr in the reciever (real value)
%               relative_snr_error: relative error of snr estimation

% Output:       output_signal : Signal after MMSE equalization

% snr estimation
snr_error_sign =2*(rand([1 1]) >= 0.5) - 1;
snr = 10^(snr_db/10);
snr = snr + snr_error_sign*snr*relative_snr_error;

% noise powers
len = size(symbols_in, 2);
p_noises = zeros(len);

for id_signal = 1:len
%     cur_p_signal = get_signal_power(symbols_in(id_symb, id_signal));
%     p_noises(id_symb, id_signal) = 2 * cur_p_signal / snr;
    p_noises(id_signal) = 1.5 / snr;
end

% find result
G = zeros(Nt, Nr, len);

for id_signal = 1:len
    G(:,:,id_signal) = H' * ((H * H' + p_noises(id_signal) * eye(Nr))\eye(Nr));
end

output = zeros(Nt, len);

for i = 1:len
    output(:, i) = G(:,:,i) * symbols_in(:, i); 
end



















