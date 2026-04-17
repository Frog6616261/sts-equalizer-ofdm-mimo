function H_fd = get_channel_matrix_by_fft(h, N_FFT)

    [Nr, Nt, sz_h] = size(h);

    sz = sz_h;
    H_fd = zeros(Nr, Nt, N_FFT);

    for i = 1:Nr
        for j = 1:Nt
            h_ij = zeros(1, N_FFT);
            h_ij(1:sz) = h(i, j, :);

            H_fd(i, j, :) = fft(h_ij);
        end
    end
end

