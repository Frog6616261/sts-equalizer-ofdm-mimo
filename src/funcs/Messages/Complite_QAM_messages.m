function QAM_messages = Complite_QAM_messages(Nt, bits, M)

symb_bits = log2(M);

% Преобразуем битовую последовательность в матрицу (M бит в строке)
bit_matrix = reshape(bits, symb_bits, []).'; % Транспонируем, чтобы каждая строка — число

% Преобразуем биты в десятичные числа
powers_of_2 = 2.^(symb_bits-1:-1:0); % Веса бит (от старшего к младшему)
messages = reshape((bit_matrix * powers_of_2.'), Nt, []);

QAM_messages = qammod(messages, M);

end