function [LLRs, exponents] = Solve_LLR_ML_algo(sym_rx, M ,H, nVar, mod_func)
%function [LLRs, exponents] = Solve_LLR_ML(sym_rx, M ,H, nVar,SNR)
% Inputs:
%   y    - [Nr x messeg_length] received vector
%   H    - [Nr x Nt] channel matrix
%   nVar - noise variance
%   M    - order of modulation
%
% Output:
%   LLRs - [(log2(M) x Nt) x messeg_length] 

[Nr, Nt] = size(H);
exponents = zeros(1, power(M, Nt));
bits_in_mod = log2(M);
bits_in_mes = bits_in_mod * Nt;
uni_bits_in_mod = pow2(bits_in_mod) - 1;
numb_exp = M^Nt;
uni_bits_arr = pow2(0:(bits_in_mes - 1));
numb_messages = size(sym_rx, 2);

% Find modulated signls
signal_by_mod = mod_func(0:M-1, M);


%% Find signals
signals_Hx = zeros(Nr, numb_exp);
x = zeros(Nt, 1);

for num_signal = 0:(numb_exp - 1)

    for level = Nt:-1:1
        x(level) = signal_by_mod(bitand(bitshift(num_signal, -(Nt - level)*bits_in_mod), uni_bits_in_mod) + 1); 
    end

    signals_Hx(:, num_signal + 1) = H * x;
end


%% Compute LLR for messages
LLRs = zeros(bits_in_mes*numb_messages,1);

for num_signal = 1:size(sym_rx,2)
    y = sym_rx(:, num_signal);

    % find all exponents
    exponents = zeros(1, power(M, Nt));

    for num_exp = 0:(numb_exp - 1)
        exponents(num_exp + 1) = exp( -( norm(y - signals_Hx(:, num_exp + 1))^2 )/(2*nVar));
    end
    
    % Compute LLRs
    for num_llr = 1:bits_in_mes
        num_bits_in_exp = bits_in_mes - num_llr + 1;
        
        sum0 = 0.0;
        sum1 = 0.0;


        for num_exp = 0:(numb_exp - 1)
            if (bitand(num_exp, uni_bits_arr(num_bits_in_exp)) == 0)
                sum0 = sum0 + exponents(num_exp + 1);
            else
                sum1 = sum1 + exponents(num_exp + 1);
            end
        end


        LLRs((num_signal-1)*bits_in_mes + num_llr) = log(sum0) - log(sum1);
    end

end

exponents = exponents.';
end




