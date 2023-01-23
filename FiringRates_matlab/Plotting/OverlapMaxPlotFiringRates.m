function OverlapMaxPlotFiringRates(xds_morn, xds_noon, unit_name, event, Save_Figs)

%% End the function if there is no Y-Limit

max_YLims = YLimit(xds_morn, xds_noon, event, unit_name);

if isnan(max_YLims)
    disp("There is no Y-Limit")
    return
end

%% Display the function being used
disp('Overlap Plot Firing Rate Function:');

%% Load the excel file
if ~ischar(unit_name)

    [xds_output] = Find_Excel(xds_morn);

    %% Find the unit of interest

    unit = xds_output.unit_names(unit_name);

else
    unit = unit_name;
end

%% Extract the target directions & centers
[target_dirs_morn, target_centers_morn] = Identify_Targets(xds_morn);
[target_dirs_noon, target_centers_noon] = Identify_Targets(xds_noon);

%% Begin the loop through all directions
avg_hists_spikes_morn = struct([]);
for jj = 1:length(target_dirs_morn)
    [avg_hists_spikes_morn{jj}, ~, bin_size] = ...
        EventWindow(xds_morn, unit_name, target_dirs_morn(jj), target_centers_morn(jj), event);
end

avg_hists_spikes_noon = struct([]);
for jj = 1:length(target_dirs_noon)
    [avg_hists_spikes_noon{jj}, ~, ~] = ...
        EventWindow(xds_noon, unit_name, target_dirs_noon(jj), target_centers_noon(jj), event);
end

%% Basic Settings, some variable extractions, & definitions

% Event lengths
before_event = 3;
after_event = 3;

if contains(event, 'gocue') || contains(event, 'force_onset')
    % Define the window for the baseline phase
    time_before_gocue = 0.4;
elseif contains(event, 'end')
    % Define the window for the movement phase
    time_before_end = xds_morn.meta.TgtHold;
end

% Font & figure specifications
label_font_size = 20;
title_font_size = 15;
plot_line_size = 3;
axes_line_size = 1.5;
legend_font_size = 12;
font_name = 'Arial';
figure_width = 750;
figure_height = 250;

%% X-axis
spike_time = (-before_event:bin_size:after_event);
spike_time = spike_time(1:end-1) + bin_size/2;
% Removing the first and last bins (to remove the histcounts error)
spike_time(:,1) = [];
spike_time(:,length(spike_time)) = [];

%% Check to see if both sessions use a consistent number of directions

% Find matching targets between the two sessions
[Matching_Idxs_Morn, Matching_Idxs_Noon] = ...
    Match_Targets(target_dirs_morn, target_dirs_noon, target_centers_morn, target_centers_noon);

if ~all(Matching_Idxs_Morn) || ~all(Matching_Idxs_Noon)
    disp('Uneven Targets Between Morning & Afternoon');
    % Only use the info of target centers conserved between morn & noon
    avg_hists_spikes_morn = avg_hists_spikes_morn(Matching_Idxs_Morn);
    avg_hists_spikes_noon = avg_hists_spikes_noon(Matching_Idxs_Noon);
end

%% Plot the two overlapped
for ii = 1:length(avg_hists_spikes_morn)

    Firing_Rate_figure = figure;
    Firing_Rate_figure.Position = [300 300 figure_width figure_height];
    hold on

    % Morning
    morn_line = plot(spike_time, avg_hists_spikes_morn{ii,1}, 'LineWidth', plot_line_size, 'Color', [0.9290, 0.6940, 0.1250]);
    % Afternoon
    noon_line = plot(spike_time, avg_hists_spikes_noon{ii,1}, 'LineWidth', plot_line_size, 'Color', [.5 0 .5]);
    
    %% Set the title, labels, axes, & plot lines indicating alignment

    % Title
    if length(unique(target_centers_noon)) == 1
        title(sprintf('Mean firing rate of %s: %i°', ... 
            char(unit), target_dirs_morn(ii)), 'FontSize', title_font_size)
    end
    if length(unique(target_centers_noon)) > 1
        title(sprintf('Mean firing rate of %s: %i°, target center at %0.1f', ... 
            char(unit), target_dirs_morn(ii), target_centers_noon(ii)), 'FontSize', title_font_size)
    end
    
    % Axis Labels
    ylabel('Firing Rate (Hz)', 'FontSize', (label_font_size - 5));
    xlabel('Time (sec.)', 'FontSize', label_font_size);

    % Setting the x-axis limits
    if contains(event, 'gocue')
        xlim([-before_event + 2, after_event]);
    elseif contains(event, 'end')
        xlim([-before_event, after_event - 2]);
    else
        xlim([-before_event + 1, after_event - 1]);
    end
    % Setting the y-axis limits
    ylim([0, max_YLims])
    ylims = ylim;

    if contains(event, 'gocue')
        % Solid dark green line indicating the aligned time
        line([0, 0], [ylims(1), ylims(2)], ...
            'LineWidth', plot_line_size, 'Color', [0 0.5 0]);
        % Dotted dark green line indicating beginning of measured window
        line([-time_before_gocue, -time_before_gocue], [ylims(1), ylims(2)], ...
            'LineWidth', plot_line_size, 'Color', [0 0.5 0], 'LineStyle','--');
    elseif contains(event, 'end')
        % Solid red line indicating the aligned time
        line([0, 0], [ylims(1), ylims(2)], ...
            'LineWidth', plot_line_size, 'color', 'r');
        % Dotted red line indicating beginning of measured window
        line([-time_before_end, -time_before_end], [ylims(1), ylims(2)], ...
            'LineWidth', plot_line_size, 'color','r','linestyle','--');
    end

    if ~contains(event, 'window')
        if ~contains(event, 'trial_gocue') && ~contains(event, 'trial_end')
            % Dotted red line indicating beginning of measured window
            line([-0.1, -0.1], [ylims(1), ylims(2)], ...
                'Linewidth', plot_line_size, 'Color', 'r', 'Linestyle','--');
            % Dotted red line indicating end of measured window
            line([0.1, 0.1], [ylims(1), ylims(2)], ...
                'Linewidth', plot_line_size, 'Color', 'r', 'Linestyle','--');
        end
    end

    % Legend
    legend([morn_line noon_line], {'Morning', 'Afternoon'}, 'Location', 'NorthEast', 'FontSize', legend_font_size);
    % Remove the legend's outline
    legend boxoff

    % Only label every other tick
    figure_axes = gca;
    figure_axes.LineWidth = axes_line_size;
    x_labels = string(figure_axes.XAxis.TickLabels);
    y_labels = string(figure_axes.YAxis.TickLabels);
    x_labels(2:2:end) = NaN;
    y_labels(2:2:end) = NaN;
    figure_axes.XAxis.TickLabels = x_labels;
    figure_axes.YAxis.TickLabels = y_labels;
    % Set ticks to outside
    set(gca,'TickDir','out');
    % Remove the top and right tick marks
    set(gca,'box','off')
    % Set The Font
    set(figure_axes,'FontName', font_name);
 
end

%% Define the save directory & save the figures
if ~isequal(Save_Figs, 0)
    save_dir = 'C:\Users\rhpow\Desktop\';
    for ii = 1:length(findobj('type','figure'))
        fig_info = get(gca,'title');
        fig_title = get(fig_info, 'string');
        fig_title = strrep(fig_title, ':', '');
        fig_title = strrep(fig_title, 'vs.', 'vs');
        fig_title = strrep(fig_title, 'mg.', 'mg');
        fig_title = strrep(fig_title, 'kg.', 'kg');
        fig_title = strrep(fig_title, '.', '_');
        fig_title = strrep(fig_title, '/', '_');
        title '';
        if ~strcmp(Save_Figs, 'All')
            saveas(gcf, fullfile(save_dir, char(fig_title)), Save_Figs)
        end
        if strcmp(Save_Figs, 'All')
            saveas(gcf, fullfile(save_dir, char(fig_title)), 'png')
            saveas(gcf, fullfile(save_dir, char(fig_title)), 'pdf')
            saveas(gcf, fullfile(save_dir, char(fig_title)), 'fig')
        end
        close gcf
    end
end



