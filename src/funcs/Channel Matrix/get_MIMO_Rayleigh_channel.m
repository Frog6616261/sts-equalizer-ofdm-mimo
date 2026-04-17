function h = get_MIMO_Rayleigh_channel(path_delay, path_gain_db, Nr, Nt)
% generates IR of Rayleigh channel
% Inputs:       path_delay    : [1 x n] Array of time delays of the signal arrival to reciever
%               path_gain_db  : [1 x n] Array of level of delayed singals
%               Nt            : [1 x 1] Number of transmitt antennas
%               Nr            : [1 x 1] Number of recieve antennas

% Output:       h : impulse response - (Nr x Nt) matrix

assert(isequal(size(path_delay), size(path_gain_db)), 'Arrays must have the same size');

if (size(path_delay, 1) > 1)
    error('Arrays must have [1 x n] dimention');
end


%% channel generation
max_t = max(path_delay);
h = zeros(Nr, Nt, max_t);
h(1, 1, max_t) = 1i*0;

path_gain_lin = db2pow(path_gain_db); 

for id_r = 1:Nr
    L = size(path_delay, 2);
    
    for id_t = 1:Nt
        temp=(randn(1,L)+1i*randn(1,L)) ./ sqrt(2); % 1 W gain coefficients

        for k = 1:L
            h(id_r, id_t, path_delay(k)) = sqrt(path_gain_lin(k)).*temp(k);
        end
    end
end


end

