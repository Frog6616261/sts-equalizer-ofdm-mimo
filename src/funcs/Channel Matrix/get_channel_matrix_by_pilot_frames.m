function H_fd = get_channel_matrix_by_pilot_frames( ...
    rx_pilot_frame_fd, tx_pilot_frame_fd)

    validateattributes(rx_pilot_frame_fd, {'numeric'}, {'3d','nonempty'}, mfilename, 'rx_pilot_frame_fd');
    validateattributes(tx_pilot_frame_fd, {'numeric'}, {'3d','nonempty'}, mfilename, 'tx_pilot_frame_fd');


    Nt_tx = size(tx_pilot_frame_fd, 2);
    Nt_rx = size(rx_pilot_frame_fd, 2);

    Nr_tx = size(tx_pilot_frame_fd, 1);
    Nr_rx = size(rx_pilot_frame_fd, 1);

    sz_tx = size(tx_pilot_frame_fd, 3);
    sz_rx = size(rx_pilot_frame_fd, 3);


    assert(Nt_tx == Nt_rx, ...
        'Nt mismatch: size(tx_pilot_frame_fd,2)=%d, size(rx_pilot_frame_fd,2)=%d.', Nt_tx, Nt_rx);

    assert(Nr_tx == Nr_rx, ...
        'Nr mismatch: size(tx_pilot_frame_fd,1)=%d, size(rx_pilot_frame_fd,1)=%d.', Nr_tx, Nr_rx);
    
    assert(sz_tx == sz_rx, ...
        '3rd-dim mismatch: size(tx_pilot_frame_fd,3)=%d, size(rx_pilot_frame_fd,3)=%d.', sz_tx, sz_rx);


    sz = sz_tx;
    H_fd = zeros(Nr_tx, Nt_tx, sz);

    for id_Fd = 1:sz
        H_fd(:, :, id_Fd) = rx_pilot_frame_fd(:, :, id_Fd) * tx_pilot_frame_fd(:, :, id_Fd);
    end
end


