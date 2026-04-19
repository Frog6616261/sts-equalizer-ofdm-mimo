function [LLRs, numb_clipping, lambda_jb, lambda_g]= Solve_LLR_STS_algo2(sym_rx, M, H, nVar, mod_func)
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
bits_in_qam = log2(M);

bits_in_mes = log2(M) * Nt;
LLRs = zeros(bits_in_mes * numb_messages, 1);
numb_clipping = 0;
mod_symbols = mod_func(0:(M-1), M);
levels = Nr:-1:1;
sigma_const = (1/(2*nVar));
max_var = pow2(bits_in_mes) - 1;
uni_bits_arr = pow2(0:(bits_in_mes - 1));
LLr_pos_by_lambda_pos = bits_in_mes:-1:1;

% QR Decomposition
[Q, R] = qr(H);
Q_H = Q';
 

for num_mes = 0:(numb_messages - 1)

sym_rx_r = Q_H * sym_rx(:, num_mes+1);
lambda_jb = inf(1, bits_in_mes);
lambda_g = inf;
main_bits = max_var;
max_lambda = zeros(1, Nt); % max lambda_ji in current layer

    %% Find Norms хахаххах нормисы, enumerations of signals
    for cur_num = 0:(power(M, Nt) - 1)
        cur_symb = zeros(Nt, 1);
        d_i = 0; % current layer distanse for signal
        %max_a = max(lambda_jb) + 2000;
        max_a = 0;

        is_list_break = false;

        %go search
        cur_bits_symb = 0;
        cur_numb = cur_num;

        for level = levels

            %find current symb         
            cur_bits_symb = rem(cur_numb, M);
            cur_numb = floor(cur_numb / M);            
            cur_symb(level) = mod_symbols(cur_bits_symb + 1);

            %find layer distanse
            e_i = sym_rx_r(level); % out signal component
            for symb_num = Nt:-1:level
                e_i = e_i - R(level, symb_num)*cur_symb(symb_num);                
            end

            d_i = d_i + norm(e_i)^2;

            % update max_a
            cur_block_num = cur_bits_symb * pow2(bits_in_qam * (Nt - level)); %need bit shift

            for bit_num = (bits_in_qam * (Nt - level) + 1) : (bits_in_qam * (Nt - level + 1)) % 1 -> 0000 0001 -> 8765 4321 

                if (bitget(main_bits, bit_num) ~= bitget(cur_block_num, bit_num)) 
                    max_a = max(max_a, lambda_jb(bit_num));
                end
            end

            max_a = max(max_lambda(level), max_a);

            % do check for distance
            if (d_i > max_a)
                is_list_break = true;
                numb_clipping = numb_clipping + 1;
                break;
            end
        end

        if (is_list_break)
            continue;
        end

    
        %calculate norm
        cur_norm = d_i;

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

        % update max_lambda
        for layer = 2:Nt
            max_lambda(layer) = max(lambda_jb( ((Nt - layer + 1) * bits_in_qam + 1) : bits_in_mes ));
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


end
    %disp("STS_done");
end
