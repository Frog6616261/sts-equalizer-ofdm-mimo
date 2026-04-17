function hh = get_MIMO_Rayleigh_channel_by_correlation_matrix(Nt, Nr, N, Rtx, Rrx, type)
% correlated Rayleigh MIMO channel coefficient
% Inputs:
% NT : number of transmitters
% NR : number of receivers
% N : length of channel matrix
% Rtx : correlation vector/matrix of Tx
% e.g.) [1 0.5], [1 0.5;0.5 1]
% Rrx : correlation vector/matrix of Rx
% type : correlation type: ’complex’ or ’field’
% Outputs:
% hh : NR x NT x N correlated channel
% uncorrelated Rayleigh fading channel, CN(1,0)

h=sqrt(1/2)*(randn(Nt*Nr,N)+1j*randn(Nt*Nr,N));
if nargin < 4
    hh=h; return; 
end % Uncorrelated channel

if isvector(Rtx)
    Rtx=toeplitz(Rtx); 
end

if isvector(Rrx)
    Rrx=toeplitz(Rrx); 
end

% Narrow band correlation coefficient
if strcmp(type,  'complex')
    C =chol(kron(Rtx,Rrx))'; % Complex correlation
else
    C =sqrtm(sqrt(kron(Rtx,Rrx))); % Power (field) correlation
end

% Apply correlation to channel matrix
hh = zeros(Nr, Nt, N);
for i=1:N
    tmp=C*h(:,i); 
    hh(:,:,i)=reshape(tmp, Nr, Nt); 
end
end
