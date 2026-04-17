function [output_signal, pilots_frame] = MIMO_generate_output_pilot_signal(Nt, fr_len, cp_length, guard_bands)
% forms an ouput signal from all transmitt antennas
% Inputs:       Nt          : Number of transmitt antennas
%               M           : Modulation order
%               fr_len      : The length of frame
%               cp_length   : The length of cyclic prefix (expected value = frame_size/2)
%               guard_bands : Unused subcarriers

% Output:       frame_with_prefix : frame in time domain with prefix

output_signal = zeros(fr_len+cp_length, Nt, Nt);
pilots_frame = zeros(fr_len, Nt, Nt);
pilots_frame_single = generate_pilots_frame(fr_len, guard_bands);
for id_t = 1:Nt
    output_signal(:,id_t, id_t) = add_cyclic_prefix(ifft(pilots_frame_single).*fr_len./sqrt(Nt), cp_length);
    pilots_frame(:,id_t, id_t) = pilots_frame_single;
end

end


% 12.06.24.
% function created
