function [LLRs, exponents] = Solve_LLR_ML_sum_exp(sym_rx, M ,H, nVar, mod_func)
% Inputs:
%   y    - [Nr x messeg_length] received vector
%   H    - [Nr x Nt] channel matrix
%   nVar - noise variance
%   M    - order of modulation
%
% Output:
%   LLRs - [(Nt*log2(M)) x messeg_length]

[Nr, Nt] = size(H);
numTx = size(H,2);
numBitsPerSym = log2(M);
totalBits = numTx * numBitsPerSym;
exponents = 1:power(M, numTx);

% Generate 16-QAM constellation
symbols = 0:M-1;
bit_table = de2bi(symbols, log2(M), 'left-msb'); 
const = mod_func(symbols, M, 'gray', 'UnitAveragePower', false);

%% Generate all n-symbol combinations (M^n total for nx16-QAM)
grid_outputs = cell(1, numTx);
[grid_outputs{:}] = ndgrid(const);
symbol_vectors = zeros(numel(grid_outputs{1}), numTx);
for i = 1:numTx
    symbol_vectors(:, i) = grid_outputs{i}(:);
end
bits_vectors = [];
for j  = 1:size(symbol_vectors,1)
    for k = 1:numTx
        [~, idx] = min(abs(symbol_vectors(j, k) - const));
        start_bit = (k-1) * numBitsPerSym + 1;
        end_bit = k * numBitsPerSym;
        bits_vectors(j,start_bit:end_bit) = bit_table(idx, :);
    end
end


%% Compute distances

LLRs = zeros(totalBits*size(sym_rx,2),1);
for t = 1:size(sym_rx,2)
    y = sym_rx(:, t);
    distances = zeros(M^Nt,1);
    for i = 1:M^Nt
        x = symbol_vectors(i, :).';
        distances(i) = norm(y - H * x)^2;

        % выводим символ и exp(-distance/(2*nVar))
        val = exp( -distances(i)/(2*nVar) );
        %fprintf('t=%d, i=%d, символ=[%g %g], exp_val=%e\n', t, i, real(floor(i/16)), real(mod(i, 16)), val);

        exponents(i) = val;
    end
    
    % Compute LLRs
    for k = 1:totalBits
        idx0 = bits_vectors(:, k) == 0;
        idx1 = bits_vectors(:, k) == 1;
    
        num = log(sum(exp( -distances(idx0)/(2*nVar) )));
        den = log(sum(exp( -distances(idx1)/(2*nVar) )));
    
        LLRs((t-1)*totalBits+ k) = num - den;
    end

end

exponents = exponents.';

end