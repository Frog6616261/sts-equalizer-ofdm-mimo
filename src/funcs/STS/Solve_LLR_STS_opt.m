function [LLRs, numb_clipping, lambda_jb, lambda_g]= Solve_LLR_STS_opt(sym_rx, M, H, nVar, mod_func)
%function [LLRs, exponents]= Calculate_LLR_STS(sym_rx, M, H, nVar)
%Inputs:
%   sym_rx [Tr x count_messages] messages
%   M [QAM] symbols
%   H [Nr x Nt] channel matrix
%   nVar noise variance
%   mod_func: qammod or bskmos or pskmod
%
%Outputs:
%   LLRs [count_messages * count_bits_in_message] 

[Nr, Nt] = size(H);
[~, numb_messages] = size(sym_rx);
bits_in_mod = log2(M);
numb_clipping = 0;

bits_in_mes = bits_in_mod * Nt;
bit_nums = 1:bits_in_mes;
LLRs = zeros(bits_in_mes * numb_messages, 1);
mod_symbols = mod_func(0:(M-1), M);    

% QR Decomposition with SQRD
% H_sigma_I = [H; 0.01*eye(Nt, Nt)];
[Q_gs, R_gs, P_gs] = qr_GS(H);
% P_gs = [2 3 1];
% [Q_gs, R_gs] = qr(H(:, P_gs));


%P_gs = 1:Nt;
R = R_gs;
LLr_pos_by_lambda_pos = get_corect_permut_vec_for_lambda(P_gs, bits_in_mod, Nt);
% LLr_pos_by_lambda_pos = bits_in_mes:-1:1;
Q_H = Q_gs(1:Nr, :)';
%disp(get_corect_permut_vec(P_gs));

% const for more clipping
L_max = 10;

%find blocks number
uni_bits_arr = pow2(0:(bits_in_mes - 1));

% constants
sigma_const = 1/(2*nVar);
max_var = pow2(bits_in_mes) - 1;
uni_bits_in_mod = pow2(bits_in_mod) - 1;

% for max_a start end arrays
start_end_arrs = zeros(Nt, bits_in_mod);

for level = Nt:-1:1
    start_end_arrs(level, :) = (bits_in_mod * (Nt - level) + 1):(bits_in_mod * (Nt - level + 1));
end

levels = Nr:-1:1;


for num_mes = 0:(numb_messages - 1)

sym_rx_r = Q_H * sym_rx(:, num_mes+1);
lambda_jb = inf(1, bits_in_mes);
lambda_g = inf;
main_bits = max_var;
max_lambda = inf(1, Nt); % max lambda_jb in current layer, считает те лямбды, которые мы можем изменить, но мы этого пока не знаем, т.к. в будущем мы не определили биты на верхних уровнях
max_lambda(1) = 0;

    %% Find Norms хахаххах нормисы, enumerations of signals
    for cur_num = 0:(power(M, Nt) - 1)
        cur_symb = zeros(Nt, 1);
        d_i = 0; 
        max_a = 0;
        max_a_after = 0; % считает максимальную изменяемую лямбду от текущего уровня до самого последнего, т.е. те которые мы знаем, что можем изменить

        is_list_break = false;

        % go search

        for level = levels          

            % find current symb 
            cur_symb(level) = mod_symbols(bitand(bitshift(cur_num, -(Nt-level)*bits_in_mod), uni_bits_in_mod) + 1); 

            % find layer distanse
            e_i = sym_rx_r(level) - R(level, level:Nt) * cur_symb(level:Nt);
            d_i = d_i + abs(e_i)^2;

            % Find max distanse that is the bourder for current distance.
            % Current distance musn't bemorre tren current bourder
            max_a = max(max_lambda(level), max_a_after);            

%             for i = (bits_in_mod * (Nt - level) + 1):bits_in_mod * (Nt - level + 1)
            for i = start_end_arrs(level, :)
                if (bitxor(bitand(main_bits, uni_bits_arr(i)), bitand(cur_num, uni_bits_arr(i))) ~= 0)
                    max_a_after = max(max_a_after, lambda_jb(i));
                end
            end  

            max_a = max(max_a, max_a_after);

%             if (max_a > max_a_n)
%                 disp("--------- \n");
%                 disp("num_mes:" + num_mes + "  cur_num:" + cur_num);
%                 disp("max_a:" + max_a + "  max_a_n:" + max_a_n);
%                 disp("level:" + level);
%                 disp(diff_mask);
%                 disp(lambda_jb);
%                 disp("");
%                 disp(lambda_jb(diff_mask));
%                 %%error("no");
%             end


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

    
        % calculate norm
        cur_norm = d_i;
        
        is_bit_changed = (bitget(main_bits, bit_nums) ~= bitget(cur_num, bit_nums));

        % check lambda general
        if (cur_norm < lambda_g)
            norm_for_lambda = min(lambda_g, cur_norm + L_max);
            
            % check lambda_jb
            lambda_jb(is_bit_changed) = norm_for_lambda;
            
            lambda_g = cur_norm;
            main_bits = cur_num;
        else
            % check lambda_jb
            is_bit_changed_jb = is_bit_changed & (lambda_jb(bit_nums) > cur_norm);
            lambda_jb(is_bit_changed_jb) = cur_norm;
        end

        % update max_lambda
        for layer = 2:Nt
            max_lambda(layer) = max(lambda_jb( ((Nt - layer + 1) * bits_in_mod + 1) : bits_in_mes ));
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


   % disp("STS_opt_done >> quantities clipping:" + string(numb_clipping));
end



function [Q, R, P] = qr_GS(H)
    [Nr, Nt] = size(H);

    if (Nt > Nr) error("Nt > Nr"); end
    if (Nr == 1 && Nt == 1) error("H isn't matrix"); end

    R = zeros(Nt, Nt);
    Q = H;
    P = 1:Nt;

    for i = 1:Nt

        % find argmin k_i
        norms = zeros(1, Nt-i+1);
        for j = i:Nt
            norms(j-i+1) = dot(Q(:, j), Q(:, j));
        end
        [~, minIndex] = min(norms);
        k_i = i + (minIndex - 1);

        % exchange colums i and k_i in Q, R, P
        Q(:, [i k_i]) = Q(:, [k_i i]);
        R(:, [i k_i]) = R(:, [k_i i]);
        P([i k_i]) = P([k_i i]);
        
        % update R and q_i
        R(i, i) = norm(Q(:, i));
        Q(:, i) = Q(:, i) / R(i, i);

        for j = (i+1):Nt
            R(i, j) = dot(Q(:, i), Q(:, j));
            Q(:, j) = Q(:, j) - R(i, j) * Q(:, i);
        end
    end 

    A = Q*R - H(:, P);
    if (not(all(abs(A(:)) <= 1e-15))) error("qr_GS not correct QR!"); end;
end


function llr_pos_by_lambda_pos = get_corect_permut_vec_for_lambda(permut_vec_by_qr, bits_in_mod, Nt)

    sz = length(permut_vec_by_qr);
    correct_permut_vec = zeros(1, sz);
    
    for idx = 1:sz
        correct_permut_vec(permut_vec_by_qr(idx)) = idx;
    end

    lambda_without_permut = (bits_in_mod*Nt):-1:1;
    lambda_permut = zeros(1, bits_in_mod*Nt);
    llr_pos_by_lambda_pos = zeros(1, bits_in_mod*Nt);
    
    for level = 1:Nt
        for num_llr_in_level = 1:bits_in_mod
            taken_pos = (correct_permut_vec(level) - 1) * bits_in_mod + num_llr_in_level;
            cur_pos = (level - 1) * bits_in_mod + num_llr_in_level;

            lambda_permut(cur_pos) = lambda_without_permut(taken_pos);
        end
    end

    for num_llr = 1:bits_in_mod*Nt
        lambda_pos = lambda_permut(num_llr);
        llr_pos_by_lambda_pos(lambda_pos) = num_llr;
    end

end


function correct_permut_vec = get_corect_permut_vec(permut_vec_by_qr)

    sz = length(permut_vec_by_qr);
    correct_permut_vec = zeros(1, sz);
    
    for idx = 1:sz
        correct_permut_vec(permut_vec_by_qr(idx)) = idx;
    end
end










