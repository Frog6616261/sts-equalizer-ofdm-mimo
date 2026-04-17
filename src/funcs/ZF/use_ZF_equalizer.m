function output = use_ZF_equalizer(symbols_in, H, Nt)

G = ((H'*H)\(eye(Nt)))* H';
output = G * (symbols_in);

end