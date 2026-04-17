function permut = get_QPP_interleaver_permutation(size_of_block)

K = size_of_block;

[f1, f2] = LTE_QPP_params(K);

permut = zeros(1, K);

for i = 0:K-1
    pi_val = mod(f1*i + f2*i*i, K);
    permut(i+1) = pi_val + 1;   % MATLAB uses 1-based indexing
end

end

