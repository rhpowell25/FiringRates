function Trial_Summary(xds_morn, xds_noon, event, unit_name, Save_File)

%% Find the unit of interest
[N_morn] = Find_Unit(xds_morn, unit_name);
[N_noon] = Find_Unit(xds_noon, unit_name);

%% Extract the target directions & centers
[target_dirs_morn, target_centers_morn] = Identify_Targets(xds_morn);
[target_dirs_noon, target_centers_noon] = Identify_Targets(xds_noon);

%% Pull the binning paramaters
[Bin_Params] = Binning_Parameters;

% Time before & after the event
before_event = Bin_Params.before_event;
after_event = Bin_Params.after_event;

% Binning information
bin_size = Bin_Params.bin_size; % Time (sec.)

% Window to calculate max firing rate
half_window_length = Bin_Params.half_window_length; % Time (sec.)

%% Begin the loop through all directions
avg_hists_spikes_morn = struct([]);
max_fr_time_morn = zeros(length(target_dirs_morn), 1);
for jj = 1:length(target_dirs_morn)
    [avg_hists_spikes_morn{jj}, max_fr_time_morn(jj)] = ...
        EventWindow(xds_morn, unit_name, target_dirs_morn(jj), target_centers_morn(jj), event);
end

avg_hists_spikes_noon = struct([]);
max_fr_time_noon = zeros(length(target_dirs_noon), 1);
for jj = 1:length(target_dirs_noon)
    [avg_hists_spikes_noon{jj}, max_fr_time_noon(jj)] = ...
        EventWindow(xds_noon, unit_name, target_dirs_noon(jj), target_centers_noon(jj), event);
end

%% Basic settings, some variable extractions, & definitions

if ~contains(event, 'window')
    max_fr_time_morn = zeros(length(target_dirs_morn), 1);
    max_fr_time_noon = zeros(length(target_dirs_noon), 1);
end

if contains(event, 'goCue') || contains(event, 'force_onset')
    % Define the window for the baseline phase
    time_before_gocue = 0.4;
elseif contains(event, 'end')
    % Define the window for the movement phase
    time_before_end = xds_morn.meta.TgtHold;
end

% Font & plotting specifications
[Plot_Params] = Plot_Parameters;
y_label_pos = -1.45;

% Extract all the spikes of the unit
morn_spikes = xds_morn.spikes{1, N_morn};
noon_spikes = xds_noon.spikes{1, N_noon};

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
    avg_hists_spikes_morn = avg_hists_spikes_morn(Matching_Idxs_Morn);
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
    [morn_rewarded_gocue_time] = EventAlignmentTimes(xds_morn, target_dirs_morn(jj), target_centers_morn(jj), 'trial_goCue');
    [noon_rewarded_gocue_time] = EventAlignmentTimes(xds_noon, target_dirs_noon(jj), target_centers_noon(jj), 'trial_goCue');

    [morn_rewarded_end_time] = EventAlignmentTimes(xds_morn, target_dirs_morn(jj), target_centers_morn(jj), 'trial_end');
    [noon_rewarded_end_time] = EventAlignmentTimes(xds_noon, target_dirs_noon(jj), target_centers_noon(jj), 'trial_end');

    [morn_Alignment_Times] = EventAlignmentTimes(xds_morn, target_dirs_morn(jj), target_centers_morn(jj), event);
    [noon_Alignment_Times] = EventAlignmentTimes(xds_noon, target_dirs_noon(jj), target_centers_noon(jj), event);

    %% Define the figure

    trial_sum_fig = figure;
    trial_sum_fig.Position = [200 50 Plot_Params.fig_size Plot_Params.fig_size];
    hold on

    % Set the common title
    Fig_Title = strcat(char(xds_morn.unit_names(N_morn)), {' '}, num2str(target_dirs_morn(jj)), ...
        '°, TgtCenter at', {' '}, num2str(target_centers_morn(jj)), {' '}, event);
    sgtitle(Fig_Title, 'FontSize', (Plot_Params.title_font_size + 5), 'Interpreter', 'None');

    sgtitle('');

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
    if contains(event, 'goCue')
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
        if ~contains(event, 'goCue')
            % Plot the go-cues as dark green dots
            plot(-morn_gocue_to_event(ii), ii, 'Marker', '.', 'Color', [0 0.5 0], 'Markersize', 15);
        end
        if ~contains(event, 'end')
            % Plot the trial ends as red dots
            plot(morn_event_to_end(ii), ii, 'Marker', '.', 'Color', 'r', 'Markersize', 15);
        end
    end

    % Axis Labels
    label = ylabel('Morning', 'FontSize', Plot_Params.label_font_size);
    label.Position(1) = y_label_pos;

    if contains(event, 'goCue')
        % Solid dark green line indicating the aligned time
        line([0, 0], [ylims(1), ylims(2)], ...
            'LineWidth', Plot_Params.mean_line_width, 'Color', [0 0.5 0]);
        % Dotted dark green line indicating beginning of measured window
        line([-time_before_gocue, -time_before_gocue], [ylims(1), ylims(2)], ...
            'LineWidth', Plot_Params.mean_line_width, 'Color', [0 0.5 0], 'LineStyle','--');
    elseif contains(event, 'end')
        % Solid red line indicating the aligned time
        line([0, 0], [ylims(1), ylims(2)], ...
            'LineWidth', Plot_Params.mean_line_width, 'color', 'r');
        % Dotted red line indicating beginning of measured window
        line([-time_before_end, -time_before_end], [ylims(1), ylims(2)], ...
            'LineWidth', Plot_Params.mean_line_width, 'color','r','linestyle','--');
    end

    if contains(event, 'window')
        % Dotted purple line indicating beginning of measured window
        line([max_fr_time_morn(jj) - half_window_length, max_fr_time_morn(jj) - half_window_length], ... 
            [ylims(1), ylims(2)], 'linewidth', Plot_Params.mean_line_width, ...
            'color',[.5 0 .5],'linestyle','--');
        % Dotted purple line indicating end of measured window
        line([max_fr_time_morn(jj) + half_window_length, max_fr_time_morn(jj) + half_window_length], ... 
            [ylims(1), ylims(2)], 'linewidth', Plot_Params.mean_line_width, ...
            'color',[.5 0 .5],'linestyle','--');
    elseif ~contains(event, 'trial_goCue') && ~contains(event, 'trial_end')
        % Dotted red line indicating beginning of measured window
        line([-0.1, -0.1], [ylims(1), ylims(2)], ...
            'Linewidth', Plot_Params.mean_line_width, 'Color', 'r', 'Linestyle','--');
        % Dotted red line indicating end of measured window
        line([0.1, 0.1], [ylims(1), ylims(2)], ...
            'Linewidth', Plot_Params.mean_line_width, 'Color', 'r', 'Linestyle','--');
    end

    % Remove the y-axis
    yticks([])

    % Axis Editing
    figure_axes = gca;
    % Set ticks to outside
    set(figure_axes,'TickDir','out');
    % Remove the top and right tick marks
    set(figure_axes,'box','off')
    % Set the tick label font size
    figure_axes.FontSize = Plot_Params.label_font_size;
    % Set The Font
    set(figure_axes,'fontname', Plot_Params.font_name);

    % Only label every other tick
    x_labels = string(figure_axes.XAxis.TickLabels);
    x_labels(1:end) = NaN;
    figure_axes.XAxis.TickLabels = x_labels;

    %% Plotting peri-event rasters for the afternoon
    
    subplot(3, 1, 2)
    hold on

    % Setting the y-axis limits
    ylim([0, length(noon_Alignment_Times)+1])
    ylims = ylim;
    % Setting the x-axis limits
    if contains(event, 'goCue')
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
        if ~contains(event, 'goCue')
            % Plot the go-cues as dark green dots
            plot(-noon_gocue_to_event(ii), ii, 'Marker', '.', 'Color', [0 0.5 0], 'Markersize', 15);
        end
        if ~contains(event, 'end')
            % Plot the trial ends as red dots
            plot(noon_event_to_end(ii), ii, 'Marker', '.', 'Color', 'r', 'Markersize', 15);
        end
    end

    % Axis Labels
    label = ylabel('Afternoon', 'FontSize', Plot_Params.label_font_size);
    label.Position(1) = y_label_pos;

    if contains(event, 'goCue')
        % Solid dark green line indicating the aligned time
        line([0, 0], [ylims(1), ylims(2)], ...
            'LineWidth', Plot_Params.mean_line_width, 'Color', [0 0.5 0]);
        % Dotted dark green line indicating beginning of measured window
        line([-time_before_gocue, -time_before_gocue], [ylims(1), ylims(2)], ...
            'LineWidth', Plot_Params.mean_line_width, 'Color', [0 0.5 0], 'LineStyle','--');
    elseif contains(event, 'end')
        % Solid red line indicating the aligned time
        line([0, 0], [ylims(1), ylims(2)], ...
            'LineWidth', Plot_Params.mean_line_width, 'color', 'r');
        % Dotted red line indicating beginning of measured window
        line([-time_before_end, -time_before_end], [ylims(1), ylims(2)], ...
            'LineWidth', Plot_Params.mean_line_width, 'color','r','linestyle','--');
    end

    if contains(event, 'window')
        % Dotted purple line indicating beginning of measured window
        line([max_fr_time_noon(jj) - half_window_length, max_fr_time_noon(jj) - half_window_length], ... 
            [ylims(1), ylims(2)], 'linewidth', Plot_Params.mean_line_width, ...
            'color',[.5 0 .5],'linestyle','--');
        % Dotted purple line indicating end of measured window
        line([max_fr_time_noon(jj) + half_window_length, max_fr_time_noon(jj) + half_window_length], ... 
            [ylims(1), ylims(2)], 'linewidth', Plot_Params.mean_line_width, ...
            'color',[.5 0 .5],'linestyle','--');
    elseif ~contains(event, 'trial_goCue') && ~contains(event, 'trial_end')
        % Dotted red line indicating beginning of measured window
        line([-0.1, -0.1], [ylims(1), ylims(2)], ...
            'Linewidth', Plot_Params.mean_line_width, 'Color', 'r', 'Linestyle','--');
        % Dotted red line indicating end of measured window
        line([0.1, 0.1], [ylims(1), ylims(2)], ...
            'Linewidth', Plot_Params.mean_line_width, 'Color', 'r', 'Linestyle','--');
    end

    % Remove the y-axis
    yticks([])

    % Axis Editing
    figure_axes = gca;
    % Set ticks to outside
    set(figure_axes,'TickDir','out');
    % Remove the top and right tick marks
    set(figure_axes,'box','off')
    % Set the tick label font size
    figure_axes.FontSize = Plot_Params.label_font_size;
    % Set The Font
    set(figure_axes,'fontname', Plot_Params.font_name);

    % Only label every other tick
    x_labels = string(figure_axes.XAxis.TickLabels);
    x_labels(1:end) = NaN;
    figure_axes.XAxis.TickLabels = x_labels;

    %% Plot the two overlapped

    subplot(3, 1, 3)
    hold on

    % Morning
    morn_line = plot(spike_time, avg_hists_spikes_morn{jj}, ...
        'LineWidth', Plot_Params.mean_line_width, 'Color', [0.9290, 0.6940, 0.1250]);
    % Afternoon
    noon_line = plot(spike_time, avg_hists_spikes_noon{jj}, ...
        'LineWidth', Plot_Params.mean_line_width, 'Color', [.5 0 .5]);

    max_YLims = YLimit(xds_morn, xds_noon, 'window_trial_goCue', unit_name);

    if contains(event, 'goCue')
        % Dotted green line indicating beginning of measured window
        line([-time_before_gocue, -time_before_gocue], [0, max_YLims], ...
            'linewidth', Plot_Params.mean_line_width,'color',[0 0.5 0],'linestyle','--');
        % Solid green line indicating the aligned time
        line([0, 0], [0, max_YLims], ...
            'linewidth', Plot_Params.mean_line_width, 'color', [0 0.5 0]);
    end
    if contains(event, 'trial_end')
        % Solid red line indicating the aligned time
        line([0, 0], [0, max_YLims], ...
            'linewidth', Plot_Params.mean_line_width, 'color', 'r');
        % Dotted red line indicating beginning of measured window
        line([-time_before_end, -time_before_end], [0, max_YLims], ...
            'linewidth', Plot_Params.mean_line_width,'color','r','linestyle','--');
    end

    % Setting the y-axis limits
    ylim([0, max_YLims])
    % Setting the x-axis limits
    if contains(event, 'goCue')
        xlim([-before_event + 2, after_event]);
    elseif contains(event, 'end')
        xlim([-before_event, after_event - 2]);
    else
        xlim([-before_event + 1, after_event - 1]);
    end
    
    label = ylabel('Firing Rate (Hz)', 'FontSize', Plot_Params.label_font_size);
    label.Position(1) = y_label_pos;
    xlabel('Time (sec.)', 'FontSize', Plot_Params.label_font_size);

    % Legend
    legend([morn_line noon_line], {'Morning', 'Afternoon'}, 'Location', 'NorthEast', ...
        'FontSize', Plot_Params.legend_size);
    % Remove the legend's outline
    legend boxoff

    % Axis Editing
    figure_axes = gca;
    figure_axes.LineWidth = Plot_Params.axis_line_width;
    % Set ticks to outside
    set(figure_axes,'TickDir','out');
    % Remove the top and right tick marks
    set(figure_axes,'box','off')
    % Set the tick label font size
    figure_axes.FontSize = Plot_Params.label_font_size;
    % Set The Font
    set(figure_axes,'fontname', Plot_Params.font_name);

    % Only label every other tick
    x_labels = string(figure_axes.XAxis.TickLabels);
    y_labels = string(figure_axes.YAxis.TickLabels);
    x_labels(2:2:end) = NaN;
    y_labels(2:2:end) = NaN;
    figure_axes.XAxis.TickLabels = x_labels;
    figure_axes.YAxis.TickLabels = y_labels;

    %% Save the file if selected
    Save_Figs(Fig_Title, Save_File)

end




