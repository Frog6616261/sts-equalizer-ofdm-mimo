function H_fd = Find_channel_matrix_by_freq( ... 
    rx_pilot_frame_fd, tx_pilot_frame_fd, N_used_start_struct, N_used_end_struct)

    Nt = size(rx_pilot_frame_fd, 2);
    Nr = size(rx_pilot_frame_fd, 1);

    sz = size(rx_pilot_frame_fd, 3);
    H_fd = zeros(Nr, Nt, sz);

    for id_Fd = N_used_start_struct.start:N_used_start_struct.end
        H_fd(:, :, id_Fd) = rx_pilot_frame_fd(:, :, id_Fd) * tx_pilot_frame_fd(:, :, id_Fd);
    end

    for id_Fd = N_used_end_struct.start:N_used_end_struct.end
        H_fd(:, :, id_Fd) = rx_pilot_frame_fd(:, :, id_Fd) * tx_pilot_frame_fd(:, :, id_Fd);
    end
end

