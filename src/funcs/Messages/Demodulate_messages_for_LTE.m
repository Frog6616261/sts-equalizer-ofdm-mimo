function bits_demod = Demodulate_messages_for_LTE(messages, mod)

messages_vec = reshape(messages, 1, []);
bits_demod = lteSymbolDemodulate(messages_vec, mod,'Soft');

end