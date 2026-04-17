function h = Generate_random_channel_matrix(Nt, Nr)

A = randn(Nr, Nt) + 1i*randn(Nr, Nt); % случайная комплексная матрица
[Q, ~] = qr(A);             % QR-разложение

% Приведение к строго унитарной форме:
for k = 1:Nt
    Q(:,k) = Q(:,k) / norm(Q(:,k)); % нормализация столбцов
end

h = Q; % унитарная матрица

% %test
% disp(h*h')


end