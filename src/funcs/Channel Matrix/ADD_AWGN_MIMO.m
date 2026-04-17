function [output_symbols, nVar] = ADD_AWGN_MIMO(symbols_in, SNR_dB)
[~, nVar] = awgn(symbols_in, SNR_dB, 'measured');
output_symbols = awgn(symbols_in, SNR_dB, 'measured');

end