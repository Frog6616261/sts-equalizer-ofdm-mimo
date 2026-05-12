function [LLRs, clipping_part_of_nodes]= Solve_LLR_STS(sym_rx, M, H, nVar, mod_func, type_func)
%function [LLRs, exponents]= Calculate_LLR_STS(sym_rx, M, H, nVar)
%Inputs:
%   sym_rx [Tr x count_messages] messages
%   M [QAM] symbols
%   H [Nr x Nt] channel matrix
%   nVar noise variance
%   mod_func: @qammod() or @bpskmod() or ...
%   type_func: 'basic' (sphere decoding with soft output); 'algo' (sum-exp with
%   algoritmic architecture); 'opt' (maximum matlab optimisations); 'puring'
%   (algorithm )
%
%Outputs:
%   LLRs [count_messages * count_bits_in_message] 
%   clipping_

switch type_func
    case 'basic'
        [LLRs, numb_clipping, ~, ~] = Solve_LLR_STS1(sym_rx, M, H, nVar, mod_func);

    case 'algo'
        [LLRs, numb_clipping, ~, ~] = Solve_LLR_STS_algo(sym_rx, M, H, nVar, mod_func);

    case 'opt'
        [LLRs, numb_clipping, ~, ~] = Solve_LLR_STS_opt(sym_rx, M, H, nVar, mod_func);

    case 'puring'
        [LLRs, numb_clipping, ~, ~] = Solve_LLR_STS_puring(sym_rx, M, H, nVar, mod_func);

    case 'purback'
        [LLRs, numb_clipping, ~, ~] = Solve_LLR_STS_puring_and_backtrecking(sym_rx, M, H, nVar, mod_func);
    
    otherwise
        error('There are not function like ' + string(type_func));
end

clipping_part_of_nodes = numb_clipping / (power(M, size(H, 2)) * size(sym_rx, 2));
end