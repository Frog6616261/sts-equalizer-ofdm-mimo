function Plotting_multiple(x, y, graphs_names, xlabel_name, ylabel_name, title_name, is_logy, directory_for_results)

% errors
if length(y) ~= length(graphs_names)
    error('y and labels is not same');
end
if length(x) ~= length(y)
    error('y and labels is not same');
end
if (is_logy)
    for i = 1:length(y)
        if any(y{i} <= 0)
            error('All variables should be > 0')
        end
    end
end

%checkfor best graphs color
key_words = ["ZF", "MMSE", "ML", "STS", "LLL", "SLLL", "RTS"];
is_match = arrayfun(@(x) any(contains(x, key_words)), graphs_names);
has_match = any(is_match);


colors = lines(length(y)+2);  
markers = {"o", "+", "square", "diamond", "v", ">", "<"};
markers_const = length(markers);


fig = figure;


% Plots all graphs
if is_logy
    for i = 1:length(y)
        % Set color
        cur_color = colors(i, :);

        if (contains(graphs_names{i}, "ZF")) cur_color = "#0033FF"; end;
        if (contains(graphs_names{i}, "MMSE")) cur_color = "#CC0000"; end;
        if (contains(graphs_names{i}, "STS")) cur_color = "#660099"; end;
        if (contains(graphs_names{i}, "ML")) cur_color = "#FFCC00"; end;
        if (contains(graphs_names{i}, "SD")) cur_color = "#00CCCC"; end;
        if (contains(graphs_names{i}, "LLL")) cur_color = "#66FF66"; end;

        if (has_match) cur_color = colors(i, :); end

        semilogy(x{i}, y{i}, 'DisplayName', graphs_names{i}, 'LineWidth', 2, 'Color', cur_color, 'LineStyle', ':', "Marker", markers(mod(i, markers_const) + 1));
        hold on;
    end
else    
    for i = 1:length(y)
        % Set color
        cur_color = colors(i, :);
        
        if (contains(graphs_names{i}, "ZF")) cur_color = "#0033FF"; end;
        if (contains(graphs_names{i}, "MMSE")) cur_color = "#CC0000"; end;
        if (contains(graphs_names{i}, "STS")) cur_color = "#660099"; end;
        if (contains(graphs_names{i}, "ML")) cur_color = "#FFCC00"; end;
        if (contains(graphs_names{i}, "SD")) cur_color = "#00CCCC"; end;
        if (contains(graphs_names{i}, "LLL")) cur_color = "#66FF66"; end;

        if (has_match) cur_color = colors(i, :); end

        plot(x{i}, y{i}, 'DisplayName', graphs_names{i}, 'LineWidth', 2, 'Color', cur_color, 'LineStyle', ':', "Marker", "+");
        hold on;
    end
end

grid on;
legend("Location", "southwest");
legend show;
xlabel(xlabel_name);
ylabel(ylabel_name);
title(title_name);

% save graph
if (~isempty(directory_for_results))
    full_name = directory_for_results + "\" + title_name + ".png";
    saveas(fig, full_name);
end


hold off;
end
