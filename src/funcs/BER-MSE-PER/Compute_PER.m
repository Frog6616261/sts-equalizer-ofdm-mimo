function per = Compute_PER(sent_packets, received_packets)
    % Проверяем, совпадают ли размеры входных матриц
    assert(isequal(size(sent_packets), size(received_packets)), ...
        'Матрицы должны быть одинакового размера');
    
    % Вычисляем количество ошибочных пакетов (столбцы, где хотя бы один символ отличается)
    num_errors = sum(any(sent_packets ~= received_packets, 1));
    
    % Общее количество пакетов
    total_packets = size(sent_packets, 2);
    
    % Расчет Packet Error Rate (PER)
    per = num_errors / total_packets;
end

