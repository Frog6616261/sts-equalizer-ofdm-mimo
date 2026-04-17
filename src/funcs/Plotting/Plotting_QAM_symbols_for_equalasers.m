function Plotting_QAM_symbols_for_equalasers(QAM_symbols_ZF, QAM_symbols_MMSE, current_snr)

figure();
hold on;
plot(real(QAM_symbols_ZF(:)), imag(QAM_symbols_ZF(:)), "*", 'DisplayName','Zero-Forcing');
plot(real(QAM_symbols_MMSE(:)), imag(QAM_symbols_MMSE(:)), "*", 'DisplayName','MMSE');
title("After equalizer SNR_dB = " + string(current_snr));
legend();
xlabel('I');
ylabel('Q'); 

end