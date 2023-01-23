function PlotFiringRates(xds, unit_name, event, max_YLims, Save_Figs)

%% End the function if there is no Y-Limit

if isnan(max_YLims)
    disp("There is no Y-Limit")
    return
end

%% Load the excel file
if ~ischar(unit_name)

    [xds_output] = Find_Excel(xds);

    %% Find the unit of interest

    unit = xds_output.unit_names(unit_name);

else
    unit = unit_name;
end

%% Extract the target directions & centers
[target_dirs, target_centers] = Identify_Targets(xds);

%% Begin the loop through all directions
avg_hists_spikes = struct([]);
for jj = 1:length(target_dirs)
    [avg_hists_spikes{jj}, max_fr_time, bin_size] = ...
        EventWindow(xds, unit_name, target_dirs(jj), target_centers(jj), event);
end

%% Basic Settings, some variable extractions, & definitions

% Event lengths
before_event = 3;
after_event = 3;

% Window to calculate max firing rate
window_size = 0.1;

if ~contains(event, 'window')
    max_fr_time = 0;
end

if contains(event, 'gocue') || contains(event, 'force_onset')
    % Define the window for the baseline phase
    time_before_gocue = 0.4;
elseif contains(event, 'end')
    % Define the window for the movement phase
    time_before_end = xds.meta.TgtHold;
end

% Font specifications
label_font_size = 20;
title_font_size = 15;
plot_line_size = 3;
axes_line_size = 1.5;
font_name = 'Arial';
figure_width = 750;
figure_height = 250;

%% X-axis
spike_time = (-before_event:bin_size:after_event);
spike_time = spike_time(1:end-1) + bin_size/2;
% Removing the first and last bins (to remove the histcounts error)
spike_time(:,1) = [];
spike_time(:,length(spike_time)) = [];

%% Plot the average firing rate
for ii = 1:length(avg_hists_spikes)
    
    Firing_Rate_figure = figure;
    Firing_Rate_figure.Position = [300 300 figure_width figure_height];
    hold on

    plot(spike_time, avg_hists_spikes{ii,1}, 'LineWidth', plot_line_size)

    %% Set the title, labels, axes, & plot lines indicating alignment

    % Title
    title(sprintf('Mean firing rate of %s: %i°, TgtCenter at %0.1f', ... 
        char(unit), target_dirs(ii), target_centers(ii)), 'FontSize', title_font_size)

    % Axis Labels
    ylabel('Firing Rate (Hz)', 'FontSize', (label_font_size - 5));
    xlabel('Time (sec.)', 'FontSize', label_font_size);

    % Setting the x-axis limits
    if contains(event, 'gocue') || contains(event, 'onset')
        xlim([-1, after_event]);
    elseif contains(event, 'end')
        xlim([-before_event, 1]);
    else
        xlim([-before_event, after_event]);
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

    if contains(event, 'window')
        % Dotted purple line indicating beginning of measured window
        line([max_fr_time - window_size, max_fr_time - window_size], ... 
            [ylims(1), ylims(2)], 'linewidth', plot_line_size,'color',[.5 0 .5],'linestyle','--');
        % Dotted purple line indicating end of measured window
        line([max_fr_time + window_size, max_fr_time + window_size], ... 
            [ylims(1), ylims(2)], 'linewidth', plot_line_size,'color',[.5 0 .5],'linestyle','--');
    elseif ~contains(event, 'trial_gocue') && ~contains(event, 'trial_end')
        % Dotted red line indicating beginning of measured window
        line([-0.1, -0.1], [ylims(1), ylims(2)], ...
            'Linewidth', plot_line_size, 'Color', 'r', 'Linestyle','--');
        % Dotted red line indicating end of measured window
        line([0.1, 0.1], [ylims(1), ylims(2)], ...
            'Linewidth', plot_line_size, 'Color', 'r', 'Linestyle','--');
    end

    % Only label every other tick
    figure_axes = gca;
    figure_axes.LineWidth = axes_line_size;
    x_labels = string(figure_axes.XAxis.TickLabels);
    y_labels = string(figure_axes.YAxis.TickLabels);
    x_labels(2:2:end) = NaN;
    y_labels(1:2:end) = NaN;
    figure_axes.XAxis.TickLabels = x_labels;
    figure_axes.YAxis.TickLabels = y_labels;
    % Set ticks to outside
    set(figure_axes,'TickDir','out');
    % Remove the top and right tick marks
    set(figure_axes,'box','off')
    % Set The Font
    set(figure_axes,'FontName', font_name);

end % End of target direction loop

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
        if strcmp(Save_Figs, 'All')
            saveas(gcf, fullfile(save_dir, char(fig_title)), 'png')
            saveas(gcf, fullfile(save_dir, char(fig_title)), 'pdf')
            saveas(gcf, fullfile(save_dir, char(fig_title)), 'fig')
        else
            saveas(gcf, fullfile(save_dir, char(fig_title)), Save_Figs)
        end
        close gcf
    end
end




