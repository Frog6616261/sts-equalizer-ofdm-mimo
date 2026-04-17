function [messages, bits, numb_bits] = Generate_messages_and_bits(Nt, numb_frames, M)

symb_bits = log2(M);
numb_bits = Nt * symb_bits * numb_frames;
bits = randi([0, 1], numb_bits, 1);

% Преобразуем битовую последовательность в матрицу (M бит в строке)
bit_matrix = reshape(bits, symb_bits, []).'; % Транспонируем, чтобы каждая строка — число

% Преобразуем биты в десятичные числа
powers_of_2 = 2.^(symb_bits-1:-1:0); % Веса бит (от старшего к младшему)
messages = reshape((bit_matrix * powers_of_2.'), Nt, []); % Умножаем матрицу на веса бит


end