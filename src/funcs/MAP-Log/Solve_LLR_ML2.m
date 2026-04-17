function [LLRs, exponents]= Solve_LLR_ML2(sym_rx, M, H, nVar)
%Inputs:
%   sym_rx [Tr x count_messages] messages
%   M [QAM] symbols
%   H [Nr x Nt] channel matrix
%   nVar noise variance
%
%Outputs:
%   LLRs [count_messages * count_bits_in_message] S

[Nr, Nt] = size(H);
[Nr, numb_messages] = size(sym_rx);

count_bits_in_message = log2(M) * Nt;
LLRs = zeros(count_bits_in_message * numb_messages, 1);
Lambda
exponents = zeros(1, power(M, Nt)); % exponents = [1 X power(M, Nt)]

    
for num_mes = 0:(numb_messages - 1)


    %% Find Exponents
    for cur_num = 0:(power(M, Nt) - 1)
        cur_symb = zeros(Nt, 1);

        %go search
        cur_bits_symb = 0;
        cur_numb = cur_num;

        for level = Nt:-1:1

            %find current symb         
            cur_bits_symb = rem(cur_numb, M);
            cur_numb = floor(cur_numb / M);            
            cur_symb(level) = qammod(cur_bits_symb, M);
        end
    
        %calculate exponent
        exponents(cur_num + 1) = exp( (-1) * (norm(sym_rx(:, (num_mes + 1)) - H*(cur_symb))^2) / (2*nVar) );
    end

    
    %% Find LLRs
    for k = 1:count_bits_in_message
        LLRs(k + (count_bits_in_message * num_mes)) = Solve_LLR_k(k, exponents, count_bits_in_message);
    end

    disp(num_mes);
end

exponents = exponents(:);

end





function LLR = Solve_LLR_k(num_llr, exponents, count_bits_in_message)

    num_bit = count_bits_in_message - num_llr + 1;
    numb_same_exp_in_row = power(2, num_bit - 1);
    step_sz = 2 * numb_same_exp_in_row;
    count_steps = power(2, count_bits_in_message - num_bit);
    
    sum_0 = 0;
    sum_1 = 0;
    
    for step = 0:(count_steps - 1)
        for num_exp = (step * step_sz + 1):(step * step_sz + numb_same_exp_in_row)
            sum_0 = sum_0 + exponents(num_exp);
            sum_1 = sum_1 + exponents(num_exp + numb_same_exp_in_row);
        end
    end
    
    LLR = log(sum_0/sum_1);

end