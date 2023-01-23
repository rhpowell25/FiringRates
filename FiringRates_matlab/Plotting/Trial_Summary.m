function Trial_Summary(xds_morn, xds_noon, event, unit_name, Save_Figs)

%% Load the excel file
if ~ischar(unit_name)

    [xds_output] = Find_Excel(xds_morn);

    %% Find the unit of interest

    unit = xds_output.unit_names(unit_name);

    %% Identify the index of the unit
    N = find(strcmp(xds_morn.unit_names, unit));

end

if ischar(unit_name) && ~strcmp(unit_name, 'All')
    N = find(strcmp(xds_morn.unit_names, unit_name));
end

%% Extract the target directions & centers
[target_dirs_morn, target_centers_morn] = Identify_Targets(xds_morn);
[target_dirs_noon, target_centers_noon] = Identify_Targets(xds_noon);

%% Begin the loop through all directions
avg_hists_spikes_morn = struct([]);
max_fr_time_morn = zeros(length(target_dirs_morn), 1);
for jj = 1:length(target_dirs_morn)
    [avg_hists_spikes_morn{jj}, max_fr_time_morn(jj), bin_size] = ...
        EventWindow(xds_morn, unit_name, target_dirs_morn(jj), target_centers_morn(jj), event);
end

avg_hists_spikes_noon = struct([]);
max_fr_time_noon = zeros(length(target_dirs_noon), 1);
for jj = 1:length(target_dirs_noon)
    [avg_hists_spikes_noon{jj}, max_fr_time_noon(jj), ~] = ...
        EventWindow(xds_noon, unit_name, target_dirs_noon(jj), target_centers_noon(jj), event);
end

%% Basic settings, some variable extractions, & definitions

% Event lengths
before_event = 3;
after_event = 3;

% Window to calculate max firing rate
window_size = 0.1;

if ~contains(event, 'window')
    max_fr_time_morn = zeros(length(target_dirs_morn), 1);
    max_fr_time_noon = zeros(length(target_dirs_noon), 1);
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
legend_font_size = 8;
font_name = 'Arial';
figure_width = 700;
figure_height = 700;

% Extract all the spikes of the unit
morn_spikes = xds_morn.spikes{1, N};
noon_spikes = xds_noon.spikes{1, N};

% Find matching targets between the two sessions
[Matching_Idxs_Morn, Matching_Idxs_Noon] = ...
    Match_Targets(target_dirs_morn, target_dirs_noon, target_centers_morn, target_centers_noon);

% Only use the info of target centers conserved between morn & noon
if ~all(Matching_Idxs_Morn) || ~all(Matching_Idxs_Noon)
    disp('Uneven Targets Between Morning & Afternoon');
    target_centers_morn = target_centers_morn(Matching_Idxs_Morn);
    target_centers_noon = target_centers_noon(Matching_Idxs_Noon);
    target_dirs_morn = target_dirs_morn(Matching_Idxs_Morn);
    target_dirs_noon = target_dirs_noon(Matching_Idxs_Noon);
    avg_hists_spikes_morn = avg_hists_spikes_morn(Matching_Idxs_Noon);
    avg_hists_spikes_noon = avg_hists_spikes_noon(Matching_Idxs_Noon);
end

% X-axis
spike_time = (-before_event:bin_size:after_event);
spike_time = spike_time(1:end-1) + bin_size/2;
% Removing the first and last bins (to remove the histcounts error)
spike_time(:,1) = [];
spike_time(:,length(spike_time)) = [];

%% Indexes for rewarded trials in all directions
% Counts the number of directions used
num_dir = length(target_dirs_morn);

%% Begin the loop through all directions
for jj = 1:num_dir

    %% Times for rewarded trials
    [morn_rewarded_gocue_time] = EventAlignmentTimes(xds_morn, target_dirs_morn(jj), target_centers_morn(jj), 'trial_gocue');
    [noon_rewarded_gocue_time] = EventAlignmentTimes(xds_noon, target_dirs_noon(jj), target_centers_noon(jj), 'trial_gocue');

    [morn_rewarded_end_time] = EventAlignmentTimes(xds_morn, target_dirs_morn(jj), target_centers_morn(jj), 'trial_end');
    [noon_rewarded_end_time] = EventAlignmentTimes(xds_noon, target_dirs_noon(jj), target_centers_noon(jj), 'trial_end');

    [morn_Alignment_Times] = EventAlignmentTimes(xds_morn, target_dirs_morn(jj), target_centers_morn(jj), event);
    [noon_Alignment_Times] = EventAlignmentTimes(xds_noon, target_dirs_noon(jj), target_centers_noon(jj), event);

    %% Define the figure

    trial_sum_fig = figure;
    trial_sum_fig.Position = [200 50 figure_width figure_height];
    hold on

    % Set the common title
    fig_title = strcat('Trial Summary -', {' '}, char(xds_morn.unit_names(N)), {' '}, num2str(target_dirs_morn(jj)), ...
        '°, TgtCenter at', {' '}, num2str(target_centers_morn(jj)));
    sgtitle(fig_title, 'FontSize', (title_font_size + 5));

    %% Times between events
    % Find time between the go-cue and reward
    morn_gocue_to_event = morn_Alignment_Times - morn_rewarded_gocue_time;
    noon_gocue_to_event = noon_Alignment_Times - noon_rewarded_gocue_time;
    morn_event_to_end = morn_rewarded_end_time - morn_Alignment_Times;
    noon_event_to_end = noon_rewarded_end_time - noon_Alignment_Times;

    %% Getting the spike timestamps based on the behavior timings above

    morn_aligned_spike_timing = struct([]);
    for ii = 1:length(morn_Alignment_Times)
        morn_aligned_spike_timing{ii, 1} = morn_spikes((morn_spikes > (morn_Alignment_Times(ii) - before_event)) & ... 
            (morn_spikes < (morn_Alignment_Times(ii) + after_event)));
    end
    noon_aligned_spike_timing = struct([]);
    for ii = 1:length(noon_Alignment_Times)
        noon_aligned_spike_timing{ii, 1} = noon_spikes((noon_spikes > (noon_Alignment_Times(ii) - before_event)) & ... 
            (noon_spikes < (noon_Alignment_Times(ii) + after_event)));
    end

    %% Plotting peri-event rasters for the morning
    
    subplot(3, 1, 1)
    hold on

    % Setting the y-axis limits
    ylim([0, length(morn_Alignment_Times)+1])
    ylims = ylim;
    % Setting the x-axis limits
    if contains(event, 'gocue')
        xlim([-before_event + 2, after_event]);
    elseif contains(event, 'end')
        xlim([-before_event, after_event - 2]);
    else
        xlim([-before_event + 1, after_event - 1]);
    end

    for ii = 1:length(morn_aligned_spike_timing)
        % The main raster plot
        plot(morn_aligned_spike_timing{ii, 1} - morn_Alignment_Times(ii), ...
            ones(1, length(morn_aligned_spike_timing{ii, 1}))*ii,... 
            'Marker', '.', 'Color', 'k', 'Markersize', 3, 'Linestyle', 'none');
        if ~contains(event, 'gocue')
            % Plot the go-cues as dark green dots
            plot(-morn_gocue_to_event(ii), ii, 'Marker', '.', 'Color', [0 0.5 0], 'Markersize', 15);
        end
        if ~contains(event, 'end')
            % Plot the trial ends as red dots
            plot(morn_event_to_end(ii), ii, 'Marker', '.', 'Color', 'r', 'Markersize', 15);
        end
    end

    % Axis Labels
    ylabel('Morning', 'FontSize', label_font_size)

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
        line([max_fr_time_morn(jj) - window_size, max_fr_time_morn(jj) - window_size], ... 
            [ylims(1), ylims(2)], 'linewidth', plot_line_size,'color',[.5 0 .5],'linestyle','--');
        % Dotted purple line indicating end of measured window
        line([max_fr_time_morn(jj) + window_size, max_fr_time_morn(jj) + window_size], ... 
            [ylims(1), ylims(2)], 'linewidth', plot_line_size,'color',[.5 0 .5],'linestyle','--');
    elseif ~contains(event, 'trial_gocue') && ~contains(event, 'trial_end')
        % Dotted red line indicating beginning of measured window
        line([-0.1, -0.1], [ylims(1), ylims(2)], ...
            'Linewidth', plot_line_size, 'Color', 'r', 'Linestyle','--');
        % Dotted red line indicating end of measured window
        line([0.1, 0.1], [ylims(1), ylims(2)], ...
            'Linewidth', plot_line_size, 'Color', 'r', 'Linestyle','--');
    end

    % Remove the y-axis
    yticks([])

    % Only label every other tick
    figure_axes = gca;
    x_labels = string(figure_axes.XAxis.TickLabels);
    x_labels(1:end) = NaN;
    figure_axes.XAxis.TickLabels = x_labels;
    % Set ticks to outside
    set(figure_axes,'TickDir','out');
    % Remove the top and right tick marks
    set(figure_axes,'box','off')
    % Set The Font
    set(figure_axes,'fontname', font_name);

    %% Plotting peri-event rasters for the morning
    
    subplot(3, 1, 2)
    hold on

    % Setting the y-axis limits
    ylim([0, length(noon_Alignment_Times)+1])
    ylims = ylim;
    % Setting the x-axis limits
    if contains(event, 'gocue')
        xlim([-before_event + 2, after_event]);
    elseif contains(event, 'end')
        xlim([-before_event, after_event - 2]);
    else
        xlim([-before_event + 1, after_event - 1]);
    end

    for ii = 1:length(noon_aligned_spike_timing)
        % The main raster plot
        plot(noon_aligned_spike_timing{ii, 1} - noon_Alignment_Times(ii), ...
            ones(1, length(noon_aligned_spike_timing{ii, 1}))*ii,... 
            'Marker', '.', 'Color', 'k', 'Markersize', 3, 'Linestyle', 'none');
        if ~contains(event, 'gocue')
            % Plot the go-cues as dark green dots
            plot(-noon_gocue_to_event(ii), ii, 'Marker', '.', 'Color', [0 0.5 0], 'Markersize', 15);
        end
        if ~contains(event, 'end')
            % Plot the trial ends as red dots
            plot(noon_event_to_end(ii), ii, 'Marker', '.', 'Color', 'r', 'Markersize', 15);
        end
    end

    % Axis Labels
    ylabel('Afternoon', 'FontSize', label_font_size)

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
        line([max_fr_time_noon(jj) - window_size, max_fr_time_noon(jj) - window_size], ... 
            [ylims(1), ylims(2)], 'linewidth', plot_line_size,'color',[.5 0 .5],'linestyle','--');
        % Dotted purple line indicating end of measured window
        line([max_fr_time_noon(jj) + window_size, max_fr_time_noon(jj) + window_size], ... 
            [ylims(1), ylims(2)], 'linewidth', plot_line_size,'color',[.5 0 .5],'linestyle','--');
    elseif ~contains(event, 'trial_gocue') && ~contains(event, 'trial_end')
        % Dotted red line indicating beginning of measured window
        line([-0.1, -0.1], [ylims(1), ylims(2)], ...
            'Linewidth', plot_line_size, 'Color', 'r', 'Linestyle','--');
        % Dotted red line indicating end of measured window
        line([0.1, 0.1], [ylims(1), ylims(2)], ...
            'Linewidth', plot_line_size, 'Color', 'r', 'Linestyle','--');
    end

    % Remove the y-axis
    yticks([])

    % Only label every other tick
    figure_axes = gca;
    x_labels = string(figure_axes.XAxis.TickLabels);
    x_labels(1:end) = NaN;
    figure_axes.XAxis.TickLabels = x_labels;
    % Set ticks to outside
    set(figure_axes,'TickDir','out');
    % Remove the top and right tick marks
    set(figure_axes,'box','off')
    % Set The Font
    set(figure_axes,'fontname', font_name);

    %% Plot the two overlapped

    subplot(3, 1, 3)
    hold on

    % Morning
    morn_line = plot(spike_time, avg_hists_spikes_morn{jj}, 'LineWidth', plot_line_size, 'Color', [0.9290, 0.6940, 0.1250]);
    % Afternoon
    noon_line = plot(spike_time, avg_hists_spikes_noon{jj}, 'LineWidth', plot_line_size, 'Color', [.5 0 .5]);

    max_YLims = YLimit(xds_morn, xds_noon, 'window_trial_gocue', unit_name);

    if contains(event, 'gocue')
        % Dotted green line indicating beginning of measured window
        line([-time_before_gocue, -time_before_gocue], [0, max_YLims], ...
            'linewidth', plot_line_size,'color',[0 0.5 0],'linestyle','--');
        % Solid green line indicating the aligned time
        line([0, 0], [0, max_YLims], ...
            'linewidth', plot_line_size, 'color', [0 0.5 0]);
    end
    if contains(event, 'trial_end')
        % Solid red line indicating the aligned time
        line([0, 0], [0, max_YLims], ...
            'linewidth', plot_line_size, 'color', 'r');
        % Dotted red line indicating beginning of measured window
        line([-time_before_end, -time_before_end], [0, max_YLims], ...
            'linewidth',plot_line_size,'color','r','linestyle','--');
    end

    % Setting the y-axis limits
    ylim([0, max_YLims])
    % Setting the x-axis limits
    if contains(event, 'gocue')
        xlim([-before_event + 2, after_event]);
    elseif contains(event, 'end')
        xlim([-before_event, after_event - 2]);
    else
        xlim([-before_event + 1, after_event - 1]);
    end
    
    ylabel('Firing Rate (Hz)', 'FontSize', label_font_size);
    xlabel('Time (sec.)', 'FontSize', label_font_size);

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
        fig_title = strrep(fig_title, ':', '');
        fig_title = strrep(fig_title, 'vs.', 'vs');
        fig_title = strrep(fig_title, 'mg.', 'mg');
        fig_title = strrep(fig_title, 'kg.', 'kg');
        fig_title = strrep(fig_title, '.', '_');
        fig_title = strrep(fig_title, '/', '_');
        %title '';
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


