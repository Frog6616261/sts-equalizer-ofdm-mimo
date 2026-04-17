function frame_with_prefix = add_cyclic_prefix(frames_td, sz_of_cp)
% adds a cyclic prefix to signal in time domain
% Inputs:       frame_td [1 x sz]  : The frame of symbols after ifft
%               l  [1 x 1]       : The length of cyclic prefix (expected value = frame_size/2)

% Output:       frame_with_prefix : frame in time domain with prefix

frame_size = size(frames_td, 2);
frame_with_prefix = zeros(1, frame_size + sz_of_cp);
frame_with_prefix(sz_of_cp + 1:(frame_size+sz_of_cp)) = frames_td;
frame_with_prefix(1:sz_of_cp) = frames_td((frame_size-sz_of_cp + 1):frame_size);

end

