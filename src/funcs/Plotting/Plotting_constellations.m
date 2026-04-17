function Plotting_constellations( ... 
    symbols_before_channel, symbols_after_conv, ...
    symbols_after_channel, symbols_after_equalizing, current_snr, ...
    is_plot_conv, is_plot_after_channel, is_plot_after_equalizer)

    symbols_before_channel = symbols_before_channel(:);
    symbols_before_channel = symbols_before_channel(1:500);

    symbols_after_conv = symbols_after_conv(:);
     symbols_after_conv = symbols_after_conv(1:500);

    symbols_after_channel = symbols_after_channel(:);
    symbols_after_channel = symbols_after_channel(1:500);

    symbols_after_equalizing = symbols_after_equalizing(:);
    symbols_after_equalizing = symbols_after_equalizing(1:500);

if (is_plot_conv)
    figure();
    hold on;
    plot(real(symbols_before_channel(:)), imag(symbols_before_channel(:)), "*", 'DisplayName','Output');
    plot(real(symbols_after_conv(:)), imag(symbols_after_conv(:)), "*", 'DisplayName','After channel');
    title("After channel SNR_dB = " + string(current_snr));
    legend();
    xlabel('I');
    ylabel('Q'); 
    hold off;
end

if (is_plot_after_channel)
    figure();
    hold on;
    plot(real(symbols_before_channel(:)), imag(symbols_before_channel(:)), "*", 'DisplayName','Output');
    plot(real(symbols_after_channel(:)), imag(symbols_after_channel(:)), "*", 'DisplayName','After channel');
    title("After channel SNR_dB = " + string(current_snr));
    legend();
    xlabel('I');
    ylabel('Q'); 
    hold off;
end

if (is_plot_after_equalizer)
    figure();
    hold on;
    plot(real(symbols_before_channel(:)), imag(symbols_before_channel(:)), "*", 'DisplayName','output');
    plot(real(symbols_after_equalizing(:)), imag(symbols_after_equalizing(:)), "*", 'DisplayName','equalize');
    title("After equalizer SNR_dB = " + string(current_snr));
    legend();
    xlabel('I');
    ylabel('Q'); 
    hold off;
end
end