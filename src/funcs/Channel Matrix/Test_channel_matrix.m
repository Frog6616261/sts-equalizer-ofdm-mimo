function Test_channel_matrix(H, M)

Nt = size(H, 2);
vars = 0:(M - 1);
signal_vals = qammod(vars(:), M);

for i = 1:power(M, Nt)
    cur_symbols = [];
    cur_num = i;

    for j = 1:Nt
        cur_id = mod(cur_num, M) + 1;
        cur_symb = signal_vals(cur_id);
        cur_symbols = [cur_symbols cur_symb];
        cur_num = floor(cur_num / M);
    end

    if (norm(H*cur_symbols(:)) - norm(cur_symbols(:))) > 1e-12
        disp(H);
        disp(cur_symbols);
        disp(norm(H*cur_symbols(:)));
        disp(norm(cur_symbols));
        error("not correct");
    end


end

end