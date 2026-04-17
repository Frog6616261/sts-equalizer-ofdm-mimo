function [LLRs, numb_clipping, lambda_jb, lambda_g]= Solve_LLR_STS_algo(sym_rx, M, H, nVar, mod_func)
%function [LLRs, exponents]= Calculate_LLR_RTS_Full(sym_rx, M, H, nVar)
%Inputs:
%   sym_rx [Tr x count_messages] messages
%   M [QAM] symbols
%   H [Nr x Nt] channel matrix
%   nVar noise variance
%
%Outputs:
%   LLRs [count_messages * count_bits_in_message] S


%% dodelat nado vse

[Nr, Nt] = size(H);
[Nr, numb_messages] = size(sym_rx);
bits_in_mod = log2(M);
mod_symbols = mod_func(0:(M-1), M);

bits_in_mes = log2(M) * Nt;
LLRs = zeros(bits_in_mes * numb_messages, 1);
numb_clipping = 0;
levels = Nt:-1:1;

%find blocks number
uni_bits_arr = pow2(0:(bits_in_mes - 1));
uni_bits_in_mod = pow2(0:(bits_in_mod - 1));

% constants
sigma_const = 1/(2*nVar);

% for max_a start end arrays
start_end_arr_in_mod = 1:bits_in_mod;


LLr_pos_by_lambda_pos = bits_in_mes:-1:1;

% QR Decomposition
[Q, R] = qr(H);
Q_H = Q';
 

for num_mes = 0:(numb_messages - 1)

sym_rx_r = Q_H * sym_rx(:, num_mes+1);
lambda_jb = inf(1, bits_in_mes); % l_1 -> num_of_bit(l_1) = 8
lambda_g = inf;
main_bits = ones(Nt, 1)*(M-1);
max_lambda = zeros(1, Nt); % max lambda_ji in current layer, that lambda we mayby can chanched, because we do not know bits on upper levels

%go search
cur_numb = 0;
last_level = 0;
last_symb = 0;
last_norm = 0;

is_complete_branch = 0;

while(cur_numb < power(M, Nt))
    cur_bits_by_lvl = ones(Nt, 1) * -1;
    level = Nt;
    cur_symb = ones(Nt, 1) * -1;
    cur_norms = ones(Nt, 1) * (-1);

    max_a = 0;
    max_a_after = 0; % that lambda we can chanched, because we know bits

    cur_norm = 0;

    while(level ~= 0)
        if is_complete_branch
            cur_bits_by_lvl(level) = last_symb; % set curren level symbol
            cur_norm = last_norm;
            is_complete_branch = 0;
        else
            cur_bits_by_lvl(level) = cur_bits_by_lvl(level) + 1; % set curren level symbol
        end

        cur_symb(level) = mod_symbols(cur_bits_by_lvl(level) + 1); % get qammod symbol for level


        % find layer distanse
        e_i = sym_rx_r(level); % out signal component
        for symb_num = Nt:-1:level
            e_i = e_i - R(level, symb_num)*cur_symb(symb_num);                
        end

        d_i = cur_norm + norm(e_i)^2;

        % update max_a
        max_a = max(max_lambda(level), max_a_after);
        
        for i = start_end_arr_in_mod
            if (bitxor(bitand(main_bits(level), uni_bits_in_mod(i)), bitand(cur_bits_by_lvl(level), uni_bits_in_mod(i))) ~= 0)
                max_a_after = max(max_a_after, lambda_jb(i));
            end
        end  
        
        max_a = max(max_a, max_a_after);

        % do check for distance
        if (d_i > max_a)
            numb_clipping = numb_clipping + power(M, level - 1);
            cur_numb = cur_numb + power(M, level - 1);

            if (cur_bits_by_lvl(level) == (M-1))
                is_complete_branch = 1;

                if cur_numb == power(M, Nt) break; end

                last_level = Nt;
                last_norm = 0;
                last_symb = cur_bits_by_lvl(Nt);

                for i = (level+1):Nt

                    if cur_bits_by_lvl(i) == (M-1) continue; end

                    last_level = i;
                    level = last_level;
                    last_symb = cur_bits_by_lvl(i) + 1;

                    if i ~= Nt last_norm = cur_norms(i + 1); end
                end                 
            end

            break;
        end

        cur_norm = d_i; % update current norm or d_i
        cur_norms(level) = cur_norm;
        level = level - 1; % update level
    end


    % there are not branches for lamdba_jb and lambda_g
    if (is_complete_branch)
        continue;
    end

    %check lambda general
    if (cur_norm < lambda_g)
        
        %check lambda_jb
        for level = levels
            for bit_num = 1:bits_in_mod
                is_bit_changed = bitget(main_bits(level), bit_num) ~= bitget(cur_bits_by_lvl(level), bit_num);
                lambda_pos = Nt*(Nt - level) + bit_num;
            
                if (is_bit_changed)
                    lambda_jb(lambda_pos) = lambda_g;
                end
            end
        end
        
        lambda_g = cur_norm;
        main_bits = cur_bits_by_lvl;
    else
        
        %check lambda_jb
        for level = levels
            for bit_num = 1:bits_in_mod
                is_bit_changed = bitget(main_bits(level), bit_num) ~= bitget(cur_bits_by_lvl(level), bit_num);
                lambda_pos = Nt*(Nt - level) + bit_num;

                if (is_bit_changed && (lambda_jb(lambda_pos) > cur_norm))
    
                    lambda_jb(lambda_pos) = cur_norm;
                end
            end
        end
    end

    % update max_lambda
    for cur_level = 2:Nt
        max_lambda(cur_level) = max(lambda_jb( ((Nt - cur_level + 1) * bits_in_mod + 1) : bits_in_mes ));
    end  

    cur_numb = cur_numb + 1; % complete one branch
end

    
%% Find LLRs
for level = levels
    for bit_num = 1:bits_in_mod
        num_lambda = Nt*(Nt - level) + bit_num;  

        if (bitand(main_bits(level), uni_bits_in_mod(bit_num)) ~= 0)
            LLRs(bits_in_mes * num_mes + LLr_pos_by_lambda_pos(num_lambda)) = (lambda_g - lambda_jb(num_lambda))*sigma_const;
        else
            LLRs(bits_in_mes * num_mes + LLr_pos_by_lambda_pos(num_lambda)) = (lambda_jb(num_lambda) - lambda_g)*sigma_const;
        end
    end
end


end
    disp("STS_done");
end
