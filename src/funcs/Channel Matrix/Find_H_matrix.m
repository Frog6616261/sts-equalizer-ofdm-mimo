function H = Find_H_matrix(h, symb_in, symb_out, Nt, Nr)
    
    noise = symb_out - (h * symb_in);
    noise_and_symb = noise ./ symb_in(1);
    noise_matrix = zeros(Nr, Nt);
    noise_matrix(:, 1) = noise_and_symb;
    
    H = h + noise_matrix;  

end