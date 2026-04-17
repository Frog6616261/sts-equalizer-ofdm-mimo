function [output_signals_td, pilots_symbols_fd] = get_pilot_symbols_for_true_channel( ...
    Nt, Nr, N_FFT, cp_length, guard_bands)

output_signals_td = zeros(Nt, Nr, cp_length + N_FFT);
pilots_symbols_fd = zeros(Nt, Nr, N_FFT);
A = N_FFT / Nt;

for id = 1:Nr
    arr_symbol_by_frame = zeros(1, Nt);
    arr_symbol_by_frame(id) = power(-1, id) + 1i*0;
    a = repmat(arr_symbol_by_frame, 1, A);
    a(guard_bands) = 0;
    output_signals_td(id, id, :) = add_cyclic_prefix(ifft(a).*N_FFT./sqrt(Nt), cp_length);
    pilots_symbols_fd(id, id, :) = a;
end


end

