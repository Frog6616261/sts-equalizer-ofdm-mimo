function [bits, numb_bits] = Generate_messages_bits(Nt, numb_frames, M)

symb_bits = log2(M);
numb_bits = Nt * symb_bits * numb_frames;
bits = randi([0, 1], 1, numb_bits);


end