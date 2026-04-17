function h = MIMO_Rayleigh_channel(path_delay, path_gain_db, Nr, Nt)
% generates IR of Rayleigh channel
% Inputs:       path_delay    : Array of time delays of the signal arrival to reciever
%               path_gain_db  : Array of level of delayed singals
%               Nt            : Number of transmitt antennas
%               Nr            : Number of recieve antennas

% Output:       h : impulse response - (Nr x Nt) matrix

assert(size(path_delay,2)==Nr & size(path_gain_db,2)==Nr, "Number of delay profiles must be the same as Nr");

%% channel generation
max_t = max([path_delay{1,1}(end) path_delay{1,2}(end)]);
h = zeros(Nr, Nt, max_t);
h(1, 1, max_t) = 1i*0;

for id_r=1:Nr
    L=length(path_delay{1,id_r});
    path_gain_lin=10.^(path_gain_db{1,id_r}/10); % power gain in linear scale
    for id_t=1:Nt
        temp=(randn(1,L)+1i*randn(1,L)) ./ sqrt(2); % 1 W gain coefficients
%         if id_t ~= id_r
%             temp = temp*0;
%         end
        for k=1:L
            h(id_r, id_t, path_delay{1,id_r}(k))=sqrt(path_gain_lin(k)).*temp(k);
        end
    end
end
end
