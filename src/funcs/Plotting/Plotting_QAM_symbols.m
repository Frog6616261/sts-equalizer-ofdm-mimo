function Plotting_QAM_symbols(QAM_symbols, is_after_channel)

scatterplot(QAM_symbols(:));

if is_after_channel
    title('Constellation after the channel');
else
    title('Constellation of symbols');
end

end