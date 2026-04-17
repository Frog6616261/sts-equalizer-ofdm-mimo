function decoded_bits = Complite_recive_bits(messages, M)

vec_messages = messages(:);
symb_bits = log2(M);

% Преобразуем числа в двоичный формат с фиксированной длиной K
bin_matrix = dec2bin(vec_messages, symb_bits) - '0'; % Преобразуем символы в числа (0 и 1)

% Разворачиваем матрицу в один вектор построчно
decoded_bits = reshape(bin_matrix', 1, []);

end
