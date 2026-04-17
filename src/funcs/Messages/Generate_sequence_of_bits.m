function [bit_seq, numb_bits] = Generate_sequence_of_bits(size_of_sequence)

    bit_seq = randi([0 1], size_of_sequence, 1);
    numb_bits = length(bit_seq);
    
end