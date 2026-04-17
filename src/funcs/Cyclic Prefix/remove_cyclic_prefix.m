function frame_without_prefix = remove_cyclic_prefix(frames_td, sz_of_cp)

frames_td = frames_td(:).';

frame_sz = size(frames_td, 2);
frame_without_prefix = frames_td((sz_of_cp+1):frame_sz);

end

