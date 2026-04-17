function h = Generate_random_flat_fading_channel_matrix(Nt, Nr)

% GENERATE_FLAT_FADING_CHANNEL  Создаёт матрицу канала Rayleigh flat fading
%
%   H = generate_flat_fading_channel(M, N)
%
%   M – число приёмных антенн
%   N – число передающих антенн
%
%   H – M×N матрица комплексных коэффициентов канала
%
%   Rayleigh fading: h = (1/sqrt(2)) * (randn + 1j * randn)

    h = (1/sqrt(2)) * (randn(Nr, Nt) + 1j * randn(Nr, Nt));
end