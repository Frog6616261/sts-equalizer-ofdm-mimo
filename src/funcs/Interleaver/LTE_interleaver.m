function y = LTE_interleaver(x)
% LTE_INTERLEAVER simple

K = length(x);

[f1, f2] = LTE_QPP_params(K);

y = zeros(size(x));

for i = 0:K-1
    pi = mod(f1*i + f2*i*i, K);
    y(pi+1) = x(i+1);
end

end

