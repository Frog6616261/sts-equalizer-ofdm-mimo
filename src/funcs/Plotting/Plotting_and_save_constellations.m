function Plotting_and_save_constellations( ... 
    symbols_before_channel, symbols_after_conv, ...
    symbols_after_channel, symbols_after_equalizing, current_snr, ...
    is_plot_conv, is_plot_after_channel, is_plot_after_equalizer, ...
    main_name_constellations, directory_for_results)

symbols_before_channel = symbols_before_channel(:);
symbols_before_channel = symbols_before_channel(1:1000);

symbols_after_conv = symbols_after_conv(:);
symbols_after_conv = symbols_after_conv(1:1000);

symbols_after_channel = symbols_after_channel(:);
symbols_after_channel = symbols_after_channel(1:1000);

symbols_after_equalizing = symbols_after_equalizing(:);
symbols_after_equalizing = symbols_after_equalizing(1:1000);


directory_for_constellations = directory_for_results + "\constellations\" + main_name_constellations;    
if ~exist(directory_for_constellations, "dir"), mkdir(directory_for_constellations); end


if (is_plot_conv)
    title_name = "After convolution SNR_dB = " + string(current_snr);
    fig = figure('Visible', 'off');
    hold on;
    plot(real(symbols_before_channel(:)), imag(symbols_before_channel(:)), "*", 'DisplayName','Output');
    plot(real(symbols_after_conv(:)), imag(symbols_after_conv(:)), "*", 'DisplayName','After channel');
    title(title_name);
    legend();
    xlabel('I');
    ylabel('Q'); 
    hold off;


    % save graph
    if (~isempty(directory_for_constellations))
        full_name = directory_for_constellations + "\" + title_name + ".png";
        saveas(fig, full_name);
    end
end

if (is_plot_after_channel)
    title_name = "After channel SNR_dB = " + string(current_snr);
    fig = figure('Visible', 'off');
    hold on;
    plot(real(symbols_before_channel(:)), imag(symbols_before_channel(:)), "*", 'DisplayName','Output');
    plot(real(symbols_after_channel(:)), imag(symbols_after_channel(:)), "*", 'DisplayName','After channel');
    title(title_name);
    legend();
    xlabel('I');
    ylabel('Q'); 
    hold off;

    % save graph
    if (~isempty(directory_for_constellations))
        full_name = directory_for_constellations + "\" + title_name + ".png";
        saveas(fig, full_name);
    end
end

if (is_plot_after_equalizer)
    title_name = "After equalizer SNR_dB = " + string(current_snr);
    fig = figure('Visible', 'off');
    hold on;
    plot(real(symbols_before_channel(:)), imag(symbols_before_channel(:)), "*", 'DisplayName','output');
    plot(real(symbols_after_equalizing(:)), imag(symbols_after_equalizing(:)), "*", 'DisplayName','equalize');
    title(title_name);
    legend();
    xlabel('I');
    ylabel('Q'); 
    hold off;

    % save graph
    if (~isempty(directory_for_constellations))
        full_name = directory_for_constellations + "\" + title_name + ".png";
        saveas(fig, full_name);
    end
end
end

