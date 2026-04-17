function H = Generate_random_channel_matrix_notHermitian(Nr, Nt, min_val, max_val)
%GENERATE_MIMO_CHANNEL  Создаёт случайную неэрмитову комплексную матрицу канала
%
%   H = generate_mimo_channel(Nr, Nt, min_val, max_val)
%
%   Входные параметры:
%       Nr  – количество приёмных антенн
%       Nt  – количество передающих антенн
%       min_val, max_val – диапазон случайных вещественных чисел
%
%   Выход:
%       H – комплексная неэрмитова матрица размера Nr×Nt

    % Случайная вещественная и мнимая часть
    real_part = (max_val - min_val) .* rand(Nr, Nt) + min_val;
    imag_part = (max_val - min_val) .* rand(Nr, Nt) + min_val;

    % Формируем комплексную матрицу
    H = real_part + 1i * imag_part;

    % Проверка: если матрица случайно получилась эрмитовой (маловероятно) —
    % слегка нарушим симметрию
    if isequal(round(H, 12), round(H', 12))
        H = H + (rand(Nr, Nt) + 1i * rand(Nr, Nt)) * 1e-3;
    end
end
