function H = Find_channel_matrix(references_symbols_matrix, receive_symbols_matrix)

I = eye(size(references_symbols_matrix));
H = receive_symbols_matrix*(references_symbols_matrix \ I);

end