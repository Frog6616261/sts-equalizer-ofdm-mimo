function LLRs = Solve_LLR_ML(sym_rx, M ,H, nVar, mod_func, type_func)
% Inputs:
%   y    - [Nr x messeg_length] received vector
%   H    - [Nr x Nt] channel matrix
%   nVar - noise variance
%   M    - order of modulation
%   mod_func: @qammod() or @bpskmod() or ...
%   type_func: 'sum-exp' (find llr by sum of exp); 'algo' (sum-exp with
%   algoritmic architecture); 'max-log' (max-log approx in sum of exp)
%
% Output:
%   LLRs - [(Nt*log2(M)) x messeg_length]

switch type_func
    case 'sum-exp'
        [LLRs, ~] = Solve_LLR_ML_sum_exp(sym_rx, M, H, nVar, mod_func);

    case 'algo'
        [LLRs, ~] = Solve_LLR_ML_algo(sym_rx, M, H, nVar, mod_func);

    case 'max-log'
        [LLRs, ~, ~] = Solve_LLR_ML_max_log(sym_rx, M, H, nVar, mod_func);

    otherwise
        error('There are not function like ' + string(type_func));
end
end