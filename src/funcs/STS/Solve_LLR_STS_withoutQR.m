function [LLRs]= Solve_LLR_STS_withoutQR(sym_rx, M, H, nVar)
%function [LLRs, exponents]= Calculate_LLR_RTS_Full(sym_rx, M, H, nVar)
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
main_bits_start = power(2, count_bits_in_message) - 1;


for num_mes = 0:(numb_messages - 1)

lambda_jb = inf(1, count_bits_in_message);
lambda_g = inf;
main_bits = 0;

    %% Find Norms хахаххах нормисы, enumerations of signals
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

            % do check for distance

        end
    
        %calculate norm
        cur_norm = norm(sym_rx(:, (num_mes + 1)) - H*(cur_symb))^2;

        %check lambda general
        if (cur_norm < lambda_g)
            
            %check lambda_jb
            for bit_num = 1:count_bits_in_message
                is_bit_changed = bitget(main_bits, bit_num) ~= bitget(cur_num, bit_num);
                
                if (is_bit_changed)
                    lambda_jb(bit_num) = lambda_g;
                end
            end

            lambda_g = cur_norm;
            main_bits = cur_num;
        else
            
            %check lambda_jb
            for bit_num = 1:count_bits_in_message
                is_bit_changed = bitget(main_bits, bit_num) ~= bitget(cur_num, bit_num);
                
                if (is_bit_changed && (lambda_jb(bit_num) > cur_norm))
                    lambda_jb(bit_num) = cur_norm;
                end
            end
        end
    end

    
    %% Find LLRs
    for k = 1:count_bits_in_message
        cur_norm_num = count_bits_in_message - k + 1;

        if (bitget(main_bits, cur_norm_num))
            LLRs(k + (count_bits_in_message * num_mes)) = (lambda_g - lambda_jb(cur_norm_num)) * (1/(2*nVar));
        else
            LLRs(k + (count_bits_in_message * num_mes)) = (lambda_jb(cur_norm_num) - lambda_g) * (1/(2*nVar));
        end        
    end


end
    disp("STS_wQR done");
end
