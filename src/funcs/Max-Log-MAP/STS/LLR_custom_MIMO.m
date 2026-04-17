function [LLRs] = LLR_custom_MIMO(sym_rx, M ,H, nVar,SNR)
    % Inputs:
%   y    - [2x messeg_length] received vector
%   H    - [Nr x Nt] channel matrix
%   nVar - noise variance
%   M    - order of modulationс
%
% Output:
%   LLRs - [8x messeg_length] LLRs for 2x 16-QAM symbols (4 bits each)
numTx = size(H,2);
numBitsPerSym = log2(M);
totalBits = numTx * numBitsPerSym;

% Generate 16-QAM constellation
symbols = 0:M-1;
bit_table = de2bi(symbols, log2(M), 'left-msb'); 
const = qammod(symbols, M, 'gray', 'UnitAveragePower', true);

% Generate all 2-symbol combinations (256 total for 2x16-QAM)
[X1, X2] = meshgrid(const, const);
symbol_vectors = [X1(:) X2(:)]; % [256 x 2]
bits_vectors = zeros(M^2, totalBits); 
% Generate corresponding bits 
for i = 1:size(symbol_vectors,1)
    [~, idx1] = min(abs(symbol_vectors(i,1) - const));
    [~, idx2] = min(abs(symbol_vectors(i,2) - const));
    b1 = bit_table(idx1, :);
    b2 = bit_table(idx2, :);
    bits_vectors(i, :) = [b1, b2];
end
after_symb = zeros(M^2,2);
for i = 1:M^2
    x = symbol_vectors(i, :).';
    after_symb(i,:) = H * x;
end
% Compute distances

LLRs = zeros(totalBits*size(sym_rx,2),1);
for t = 1:size(sym_rx,2)
y = sym_rx(:, t);
distances = zeros(M^2,1);
for i = 1:M^2
    x = symbol_vectors(i, :).';
    distances(i) = norm(y - H * x)^2;
end

% Compute LLRs
for k = 1:totalBits
    idx0 = bits_vectors(:, k) == 0;
    idx1 = bits_vectors(:, k) == 1;

    max0 = max(-distances(idx0)/(2*nVar));
    max1 = max(-distances(idx1)/(2*nVar));

    num = max0 + log(sum(exp((-distances(idx0)/(2*nVar)) - max0)));
    den = max1 + log(sum(exp((-distances(idx1)/(2*nVar)) - max1)));

    LLRs((t-1)*totalBits+ k) = num - den;
end

end

end