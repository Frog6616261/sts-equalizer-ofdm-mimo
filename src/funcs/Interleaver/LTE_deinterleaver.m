function x = LTE_deinterleaver(y)
% LTE_DEINTERLEAVER simple

K = length(y);
[f1, f2] = LTE_QPP_params(K);

x = zeros(size(y));

for i = 0:K-1
    pi = mod(f1*i + f2*i*i, K);
    x(i+1) = y(pi+1);
end

end


