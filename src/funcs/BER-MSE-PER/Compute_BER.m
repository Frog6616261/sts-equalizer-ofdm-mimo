function ber = Compute_BER(sent_bits, received_bits)
    % Проверяем, совпадают ли размеры входных матриц
    assert(isequal(size(sent_bits), size(received_bits)), ...
        'Матрицы должны быть одинакового размера');
    
    % Вычисляем количество ошибочных пакетов (столбцы, где хотя бы один символ отличается)
    num_errors = sum(any(sent_bits ~= received_bits, 1));
    
    % Общее количество пакетов
    total_packets = size(sent_bits, 2);
    
    % Расчет Packet Error Rate (BER)
    ber = num_errors / total_packets;
end
