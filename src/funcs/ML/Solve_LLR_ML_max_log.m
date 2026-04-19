function [LLRs, lambda_jb, lambda_g]= Solve_LLR_ML_max_log(sym_rx, M, H, nVar, mod_func)
%Inputs:
%   sym_rx [Tr x count_messages] messages
%   M [QAM] symbols
%   H [Nr x Nt] channel matrix
%   nVar noise variance
%
%Outputs:
%   LLRs [count_messages * count_bits_in_message] 

[Nr, Nt] = size(H);
[Nr, numb_messages] = size(sym_rx);

bits_in_mes = log2(M) * Nt;
LLRs = zeros(bits_in_mes * numb_messages, 1);


mod_symbols = mod_func(0:(M-1), M);
levels = Nr:-1:1;
sigma_const = (1/(2*nVar));
max_var = pow2(bits_in_mes) - 1;
uni_bits_arr = pow2(0:(bits_in_mes - 1));
LLr_pos_by_lambda_pos = bits_in_mes:-1:1;
    
for num_mes = 0:(numb_messages - 1)
main_bits = max_var;
lambda_jb = inf(1, bits_in_mes);
lambda_g = inf;

    %% Find Norms хахаххах нормисы
    for cur_num = 0:(power(M, Nt) - 1)
        cur_symb = zeros(Nt, 1);

        %go search
        cur_bits_symb = 0;
        cur_numb = cur_num;

        for level = levels

            %find current symb         
            cur_bits_symb = rem(cur_numb, M);
            cur_numb = floor(cur_numb / M);            
            cur_symb(level) = mod_symbols(cur_bits_symb + 1);

            % do check for distance

        end
    
        %calculate norm
        cur_norm = norm(sym_rx(:, (num_mes + 1)) - H*(cur_symb))^2;

%         %check minimal norm_0 or norm_1
%         for bit_num = 1:count_bits_in_message
%             cur_bit_val = bitand(bitshift(cur_num, -(bit_num - 1)), 1);
% 
% 
%             if (cur_bit_val && min_norms_1(bit_num) > cur_norm)
%                 min_norms_1(bit_num) = cur_norm;
%                 continue;
%             end
% 
%             if (min_norms_0(bit_num) > cur_norm)
%                 min_norms_0(bit_num) = cur_norm;
%             end
%         end

        %check lambda general
        if (cur_norm < lambda_g)
            
            %check lambda_jb
            for bit_num = 1:bits_in_mes
                is_bit_changed = bitget(main_bits, bit_num) ~= bitget(cur_num, bit_num);
                
                if (is_bit_changed)
                    lambda_jb(bit_num) = lambda_g;
                end
            end
            
            lambda_g = cur_norm;
            main_bits = cur_num;
        else
            
            %check lambda_jb
            for bit_num = 1:bits_in_mes
                is_bit_changed = bitget(main_bits, bit_num) ~= bitget(cur_num, bit_num);
                
                if (is_bit_changed && (lambda_jb(bit_num) > cur_norm))

                    lambda_jb(bit_num) = cur_norm;
                end
            end
        end
    end


    %% Write LLRs into an result
    for num_lambda = 1:bits_in_mes
        if (bitand(main_bits, uni_bits_arr(num_lambda)) ~= 0)
            LLRs(bits_in_mes * num_mes + LLr_pos_by_lambda_pos(num_lambda)) = (lambda_g - lambda_jb(num_lambda))*sigma_const;
        else
            LLRs(bits_in_mes * num_mes + LLr_pos_by_lambda_pos(num_lambda)) = (lambda_jb(num_lambda) - lambda_g)*sigma_const;
        end        
    end

    %disp(num_mes);
end
end



