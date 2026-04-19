function [LLRs, numb_clipping, lambda_jb, lambda_g]= Solve_LLR_STS1(sym_rx, M, H, nVar, mod_func)
%function [LLRs, exponents]= Calculate_LLR_STS(sym_rx, M, H, nVar)
%Inputs:
%   sym_rx [Tr x count_messages] messages
%   M [QAM] symbols
%   H [Nr x Nt] channel matrix
%   nVar noise variance
%
%Outputs:
%   LLRs [count_messages * count_bits_in_message] 

[~, Nt] = size(H);
[~, numb_messages] = size(sym_rx);
bits_in_qam = log2(M);
numb_clipping = 0;

count_bits_in_message = bits_in_qam * Nt;
LLRs = zeros(count_bits_in_message * numb_messages, 1);
mod_symbols = mod_func(0:(M-1), M);    

% QR Decomposition with SQRD
[Q, R] = qr(H);
Q_H = Q';


% const for more clipping
L_max = 10;


for num_mes = 0:(numb_messages - 1)

sym_rx_r = Q_H * sym_rx(:, num_mes+1);
lambda_jb = inf(1, count_bits_in_message);
lambda_g = inf;
main_bits = pow2(count_bits_in_message) - 1;
max_lambda = zeros(1, Nt); % max lambda_jb in current layer

    %% Find Norms хахаххах нормисы, enumerations of signals
    for cur_num = 0:(power(M, Nt) - 1)
        cur_symb = zeros(Nt, 1);
        d_i = 0; % current layer distanse for signal
        max_a = 0;

        is_list_break = false;

        % go search
        % Start block Nt_end. First bit in main_bits = Last LLR component
        cur_bits_symb = 0;
        cur_numb = cur_num;

        for level = Nt:-1:1

            % find current symb         
            cur_bits_symb = rem(cur_numb, M);
            cur_numb = floor(cur_numb / M);            
            cur_symb(level) = mod_symbols(cur_bits_symb + 1);

            % find layer distanse
            e_i = sym_rx_r(level) - R(level, level:Nt) * cur_symb(level:Nt);
            d_i = d_i + abs(e_i)^2;

            % update max_a
            % check current Nt bitr => level bits. There are...
            % only count_bits_in_message checked
            bit_range = (bits_in_qam * (Nt - level) + 1) : (bits_in_qam * (Nt - level + 1));
            cur_block_num = cur_bits_symb * 2^(bits_in_qam * (Nt - level));
            diff_mask = bitget(main_bits, bit_range) ~= bitget(cur_block_num, bit_range);            

            if any(diff_mask)
                max_a = max(max_lambda(level), max(max_a, max(lambda_jb(diff_mask))));
            else
                max_a = max(max_lambda(level), max_a);
            end


            % check for clipping
            if (d_i > max_a)
                is_list_break = true;
                break;
            end
        end

        if (is_list_break)
            numb_clipping = numb_clipping + 1;
            continue;
        end

    
        %calculate norm
        cur_norm = d_i;

        bit_nums = 1:count_bits_in_message;
        is_bit_changed = bitget(main_bits, bit_nums) ~= bitget(cur_num, bit_nums);

        %check lambda general
        if (cur_norm < lambda_g)
            norm_for_lambda = min(lambda_g, cur_norm + L_max);
            
            %check lambda_jb
            lambda_jb(is_bit_changed) = norm_for_lambda;
            
            lambda_g = cur_norm;
            main_bits = cur_num;
        else
            %check lambda_jb
            is_bit_changed_jb = is_bit_changed & (lambda_jb(bit_nums) > cur_norm);
            lambda_jb(is_bit_changed_jb) = cur_norm;
        end

        % update max_lambda
        for layer = 2:Nt
            max_lambda(layer) = max(lambda_jb( ((Nt - layer + 1) * bits_in_qam + 1) : count_bits_in_message ));
        end   
    end


    %% Find LLRs
    cur_norm_num = count_bits_in_message:-1:1;
    bit_mask = bitget(main_bits, cur_norm_num);
    LLR_part = (2*bit_mask - 1).*(lambda_g - lambda_jb(cur_norm_num))*(1/(2*nVar));         
    LLRs(count_bits_in_message * num_mes + 1: count_bits_in_message * (num_mes + 1)) = LLR_part;
end

    %disp("STS_done >> numb clippings: " + string(numb_clipping));
end