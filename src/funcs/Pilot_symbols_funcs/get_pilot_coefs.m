function pilot_symbols_fd = get_pilot_coefs(...
    Nt, Nr, N_used)

pilot_symbols_fd = zeros(Nt, Nr, N_used);

for id = 1:Nr
    pilot_symbols_fd(id, id, :) = power(-1, id) + 1i*0;
end


end
