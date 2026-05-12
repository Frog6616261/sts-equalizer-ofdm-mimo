function [LLRs, numb_clipping, lambda_jb, lambda_g] = Solve_LLR_STS_puring_and_backtrecking_1(sym_rx, M, H, nVar, mod_func)
% realisation with puring and backtrecking
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
bits_in_mod = log2(M);

bits_in_mes = log2(M) * Nt;
LLRs = zeros(bits_in_mes * numb_messages, 1);
numb_clipping = 0;
mod_symbols = mod_func(0:(M-1), M);
levels = Nt:-1:1;
sigma_const = (1/(2*nVar));
max_var = pow2(bits_in_mes) - 1;
uni_bits_arr = pow2(0:(bits_in_mes - 1));
LLr_pos_by_lambda_pos = bits_in_mes:-1:1;

% QR Decomposition
[Q, R] = qr(H);
Q_H = Q';

% all symbols
[NUMBS_TREE_LVL, SYMB_TREE_LVL] = buildMTreeLevels_v2(M, Nt, mod_symbols);
NUMS = mAryVectorsToNumbers(NUMBS_TREE_LVL, M);


% for max_a start end arrays
start_end_arrs = zeros(Nt, bits_in_mod);
for level = Nt:-1:1
    start_end_arrs(level, :) = (bits_in_mod * (Nt - level) + 1):(bits_in_mod * (Nt - level + 1));
end
 

for num_mes = 0:(numb_messages - 1)

sym_rx_r = Q_H * sym_rx(:, num_mes+1);
lambda_jb = inf(1, bits_in_mes);
lambda_g = inf;
main_bits = max_var;
max_lambda = zeros(1, Nt); %inf(1, Nt);
cur_num = 1;
last_num = 1;
cur_weights = zeros(1, Nt+1);
min_lvl_of_weight = Nt;

is_full_leaf_was = false;
max_a = zeros(1, Nt+1);
max_a_after = zeros(1, Nt+1); % that lambda we can chanched, because we know bits

    %% Find, enumerations of signals
    while (cur_num ~= (power(M, Nt) + 1))
        is_list_break = false;

        % backtrecking
        % find start level
        lvl = Nt;
        while (lvl > min_lvl_of_weight)
            if (NUMBS_TREE_LVL(lvl, last_num) ~= NUMBS_TREE_LVL(lvl, cur_num))
                break;
            end

            lvl = lvl - 1;
        end

        % set current params
        cur_numb = NUMS(cur_num);
        cur_symb = SYMB_TREE_LVL(:, cur_num);

        % re-update max_a
        if (is_full_leaf_was)  
            level = Nt;
            while (level > lvl)
                max_a(level) = max(max_lambda(level), max_a_after(level+1));  
                
                % find max metric for current level that we can use
                for i = start_end_arrs(level, :)
                    if (bitxor(bitand(main_bits, uni_bits_arr(i)), bitand(cur_numb, uni_bits_arr(i))) ~= 0)             
                        if (max_a_after(level) == Inf)
                            max_a_after(level) = lambda_jb(i);
                        else
                            max_a_after(level) = max(max_a_after(level), lambda_jb(i));
                        end
                    end
                end  
    
                max_a(level) = max(max_a(level), max_a_after(level));  
                level = level - 1;
            end
            
            is_full_leaf_was = false;
        end

        % go search 
        while (lvl >= 1)
%             %find current symb         
%             cur_bits_symb = rem(cur_numb, M);
%             cur_numb = floor(cur_numb / M);

            %find layer distanse
            e_i = sym_rx_r(lvl); % out signal component
            for symb_num = Nt:-1:lvl
                e_i = e_i - R(lvl, symb_num)*cur_symb(symb_num);                
            end

            cur_weights(lvl) = cur_weights(lvl+1) + norm(e_i)^2;

            % update max_a
            max_a(lvl) = max(max_lambda(lvl), max_a_after(lvl+1));  

            % find max metric for current level that we can use
            for i = start_end_arrs(lvl, :)
                if (bitxor(bitand(main_bits, uni_bits_arr(i)), bitand(cur_numb, uni_bits_arr(i))) ~= 0)
                    if (max_a_after(lvl) == Inf)
                        max_a_after(lvl) = lambda_jb(i);
                    else
                        max_a_after(lvl) = max(max_a_after(lvl), lambda_jb(i));
                    end
                end
            end  

            max_a(lvl) = max(max_a(lvl), max_a_after(lvl));

            % do check for distance and puring and backtrecking
            if (cur_weights(lvl) > max_a(lvl))

                % count clipping
                cur_shift = power(M, (lvl - 1));
                numb_clipping = numb_clipping + cur_shift;

                % set last and cur 
                % numers
                last_num = cur_num;
                cur_num = cur_num + cur_shift;

                % set level for end search
                min_lvl_of_weight = lvl;

                % do next symbol
                is_list_break = true;
                break;
            end

            lvl = lvl - 1;
        end

        if (is_list_break)
            continue;
        end

    
        %calculate norm
        cur_norm = cur_weights(1);

        %check lambda general
        if (cur_norm < lambda_g)
            
            %check lambda_jb
            for bit_num = 1:bits_in_mes
                is_bit_changed = bitget(main_bits, bit_num) ~= bitget(cur_numb, bit_num);
                
                if (is_bit_changed)
                    lambda_jb(bit_num) = lambda_g;
                end
            end
            
            lambda_g = cur_norm;
            main_bits = cur_numb;
        else
            
            %check lambda_jb
            for bit_num = 1:bits_in_mes
                is_bit_changed = bitget(main_bits, bit_num) ~= bitget(cur_numb, bit_num);
                
                if (is_bit_changed && (lambda_jb(bit_num) > cur_norm))

                    lambda_jb(bit_num) = cur_norm;
                end
            end
        end

        % update max_lambda
        for layer = 2:Nt
            max_lambda(layer) = max(lambda_jb( ((Nt - layer + 1) * bits_in_mod + 1) : bits_in_mes ));
        end

        is_full_leaf_was = true;
        min_lvl_of_weight = 1;
        last_num = cur_num;
        cur_num = cur_num + 1;
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

function [A, B] = buildMTreeLevels_v2(M, Nt, mod_symbols)
% Размер: [Nt x M^Nt]
% Строка 1 — самый быстрый уровень (меняется первым)

    numCols = M^Nt;
    A = zeros(Nt, numCols);
    B = zeros(Nt, numCols);

    for col = 0:numCols-1
        x = col;

        for level = 1:Nt
            A(level, col+1) = mod(x, M);
            B(level, col+1) = mod_symbols((A(level, col+1) + 1));
            x = floor(x / M);
        end
    end
end


function nums = mAryVectorsToNumbers(A, M)
% A    : [Nt x M^Nt]
% nums : [1 x M^Nt]

    Nt = size(A, 1);

    powers = M.^((Nt-1):-1:0).';   % [Nt x 1]
    nums = powers.' * A;           % [1 x M^Nt]
end

