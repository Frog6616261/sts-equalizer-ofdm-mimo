function [LLRs,bits] = LLR_custom(sym_rx, M ,nVar)
%LLR_CUSTOM Summary of this function goes here
%   Get sybwols with our type of modulatin where M order of modulation, nVar level of noise variance, sys_rx  


bits = de2bi(0:M-1, log2(M), 'left-msb');
const = qammod(0:M-1, M,"bin");

numBitsPerSym = log2(M);
numSymbols = length(sym_rx);
LLRs = zeros(numBitsPerSym * numSymbols, 1);
for k= 1:numBitsPerSym
    for i = 1:numSymbols
        y = sym_rx(i);
            
        % Symbols where bit k = 0 and bit k = 1
        sym0 = const(bits(:,k) == 0);
        sym1 = const(bits(:,k) == 1);
            
        % Compute distances
        d0 = abs(y - sym0).^2;
        d1 = abs(y - sym1).^2;
            
        % Numerator and denominator using log-sum-exp trick
        max0 = -min(d0)/nVar;
        max1 = -min(d1)/nVar;
            
        num = max0 + log(sum(exp((-d0/nVar) - max0)));
        den = max1 + log(sum(exp((-d1/nVar) - max1)));
            
        % Final LLR
        LLRs((i-1)*numBitsPerSym + k) = num - den;
    end
end
end

