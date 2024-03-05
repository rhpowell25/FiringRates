function OverlapMaxPlotFiringRates(xds_morn, xds_noon, unit_name, event, Save_File)

%% End the function if there is no Y-Limit

max_YLims = YLimit(xds_morn, xds_noon, event, unit_name);

if isnan(max_YLims)
    disp("There is no Y-Limit")
    return
end

%% Display the function being used
disp('Overlap Plot Firing Rate Function:');

%% Find the unit of interest
[N] = Find_Unit(xds_morn, unit_name);
unit = xds_morn.unit_names(N);

%% Extract the target directions & centers
[target_dirs_morn, target_centers_morn] = Identify_Targets(xds_morn);
[target_dirs_noon, target_centers_noon] = Identify_Targets(xds_noon);

%% Begin the loop through all directions
avg_hists_spikes_morn = struct([]);
for jj = 1:length(target_dirs_morn)
    [Alignment_Times] = EventAlignmentTimes(xds_morn, ...
        target_dirs_morn(jj), target_centers_morn(jj), event);
    [avg_hists_spikes_morn{jj}] = Avg_Hist_Spikes(xds_morn, unit_name, Alignment_Times);
end

avg_hists_spikes_noon = struct([]);
for jj = 1:length(target_dirs_noon)
    [Alignment_Times] = EventAlignmentTimes(xds_noon, ...
        target_dirs_noon(jj), target_centers_noon(jj), event);
    [avg_hists_spikes_noon{jj}] = Avg_Hist_Spikes(xds_noon, unit_name, Alignment_Times);
end

%% Basic Settings, some variable extractions, & definitions

% Pull the binning paramaters
[Bin_Params] = Binning_Parameters;

% Time before & after the event
before_event = Bin_Params.before_event;
after_event = Bin_Params.after_event;

% Binning information
bin_size = Bin_Params.bin_size; % Time (sec.)

if contains(event, 'gocue') || contains(event, 'force_onset')
    % Define the window for the baseline phase
    time_before_gocue = 0.4;
elseif contains(event, 'end')
    % Define the window for the movement phase
    time_before_end = xds_morn.meta.TgtHold;
end

% Font & plotting specifications
[Plot_Params] = Plot_Specs;

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
    Firing_Rate_figure.Position = [300 300 Plot_Params.fig_size Plot_Params.fig_size / 2];
    hold on

    % Morning
    morn_line = plot(spike_time, avg_hists_spikes_morn{ii}, ...
        'LineWidth', Plot_Params.mean_line_width, 'Color', [0.9290, 0.6940, 0.1250]);
    % Afternoon
    noon_line = plot(spike_time, avg_hists_spikes_noon{ii}, ...
        'LineWidth', Plot_Params.mean_line_width, 'Color', [.5 0 .5]);
    
    %% Set the title, labels, axes, & plot lines indicating alignment

    % Title
    if length(unique(target_centers_noon)) == 1
        Fig_Title = strcat('Mean firing rate of', {' '}, char(unit), ':', ...
            {' '}, target_dirs_morn(ii), '°');
    end
    if length(unique(target_centers_noon)) > 1
        Fig_Title = strcat('Mean firing rate of', {' '}, char(unit), ':', ...
            {' '}, string(target_dirs_morn(ii)), '°, target center at', ...
            {' '}, string(target_centers_noon(ii)));
    end
    title(Fig_Title, 'FontSize', Plot_Params.title_font_size)
    
    % Axis Labels
    ylabel('Firing Rate (Hz)', 'FontSize', (Plot_Params.label_font_size - 5));
    xlabel('Time (sec.)', 'FontSize', Plot_Params.label_font_size);

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

    if ~contains(event, 'window')
        if ~contains(event, 'trial_gocue') && ~contains(event, 'trial_end')
            % Dotted red line indicating beginning of measured window
            line([-0.1, -0.1], [ylims(1), ylims(2)], ...
                'Linewidth', Plot_Params.mean_line_width, 'Color', 'r', 'Linestyle','--');
            % Dotted red line indicating end of measured window
            line([0.1, 0.1], [ylims(1), ylims(2)], ...
                'Linewidth', Plot_Params.mean_line_width, 'Color', 'r', 'Linestyle','--');
        end
    end

    % Legend
    legend([morn_line noon_line], {'Morning', 'Afternoon'}, 'Location', 'NorthEast', ...
        'FontSize', Plot_Params.legend_size);
    % Remove the legend's outline
    legend boxoff

    % Only label every other tick
    figure_axes = gca;
    figure_axes.LineWidth = Plot_Params.axis_line_width;
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
    set(figure_axes,'FontName', Plot_Params.font_name);

    %% Save the file if selected
    Save_Figs(Fig_Title, Save_File)
 
end



