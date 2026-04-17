function messages = Complite_messages_for_LTE(Nt, bits, mod)

symbols = lteSymbolModulate(bits, mod);
messages = reshape(symbols, Nt, []);

end