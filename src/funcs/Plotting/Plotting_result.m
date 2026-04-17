function Plotting_result(result, names_of_results)

if not(size(result, 2) == size(names_of_results, 2))
    error("results.size != names_of_results.size")
end

num_snr = 0;
nums_ber = [];
nums_evm = [];

%find all tags
for i = 1:size(names_of_results, 2)
    cur_str = names_of_results(i);

    if cur_str{1}(1) == "B" || cur_str(1) == "b" 
        nums_ber = [nums_ber i];
        continue;
    end

    if cur_str{1}(1) == "E" || cur_str(1) == "e" 
        nums_evm = [nums_evm i];
        continue;
    end

    if cur_str{1}(1) == "S" || cur_str(1) == "s" 
        num_snr = i;
        continue;
    end

    error("not correct tags name");
end

%% Plotting BER 
figure();

for i = 1:size(nums_ber, 2)    
    semilogy(result(:, num_snr), result(:, nums_ber(i)), 'DisplayName', names_of_results(nums_ber(i)));
    legend show;
    xlabel('SNR dB');  
    ylabel('BER');  
    title('BER');  
    grid on;
    hold on;    
end

hold off;


%% Plotting EVM
figure();

for i = 1:size(nums_evm, 2)    
    semilogy(result(:, num_snr), result(:, nums_evm(i)), 'DisplayName', names_of_results(nums_evm(i)));
    hold on;    
end
legend show;
xlabel('SNR dB');  
ylabel('EVM');  
title('EVM'); 
grid on;
hold off;

end