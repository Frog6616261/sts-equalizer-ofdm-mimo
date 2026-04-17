function mse_mean = Compute_MSE(sent_packets, received_packets)
    % Проверяем, совпадают ли размеры входных матриц
    assert(isequal(size(sent_packets), size(received_packets)), ...
        'Матрицы должны быть одинакового размера');

    % Вычисляем квадрат ошибки для каждого элемента
    squared_errors = abs(sent_packets - received_packets).^2;

    % Среднеквадратичная ошибка (MSE) для каждого пакета (считаем среднее по строкам)
    mse_per_packet = mean(squared_errors, 1);

    % Средняя ошибка по всем пакетам
    mse_mean = mean(mse_per_packet);
end