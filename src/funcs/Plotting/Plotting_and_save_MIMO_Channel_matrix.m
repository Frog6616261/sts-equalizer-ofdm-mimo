function Plotting_and_save_MIMO_Channel_matrix( h, ...
    main_name, directory_for_results)


directory_for_impulse_response = directory_for_results + "\impulse_response\" + main_name;    
if ~exist(directory_for_impulse_response, "dir"), mkdir(directory_for_impulse_response); end

[Nr, Nt, sz] = size(h);
time_sequence = 1:sz;


for id_Nr = 1:Nr
    for id_Nt = 1:Nt
        title_name = main_name + "channel component h" + string(id_Nr) + string(id_Nt);
        title_gain_dB = "channel gain, component h";
        title_phase = "channel phase";

        fig = figure('Visible', 'off');
        t = tiledlayout(2,1);
        
        nexttile;
        stem(time_sequence, pow2db(abs(squeeze(h(id_Nr, id_Nt, :)))));
        title(title_gain_dB);
        xlabel("time sec");
        ylabel("Amp dB"); 
        grid on;

        nexttile;
        stem(time_sequence, angle(squeeze(h(id_Nr, id_Nt, :))));
        title(title_phase);
        xlabel("time sec");
        ylabel("Phase rad");
        grid on;

        title(t, title_name);
    
    
        % save graph
        if (~isempty(directory_for_impulse_response))
            full_name = directory_for_impulse_response + "\" + title_name + ".png";
            saveas(fig, full_name);
        end
    end
end

end

