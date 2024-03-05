function PlotFiringRates(xds, unit_name, event, max_YLims, Save_File)

%% End the function if there is no Y-Limit

if isnan(max_YLims)
    disp("There is no Y-Limit")
    return
end

%% Find the unit of interest
[N] = Find_Unit(xds, unit_name);
unit = xds.unit_names(N);

%% Extract the target directions & centers
[target_dirs, target_centers] = Identify_Targets(xds);

%% Begin the loop through all directions
avg_hists_spikes = struct([]);
max_fr_time = zeros(length(target_dirs),1);
for jj = 1:length(target_dirs)
    [Alignment_Times] = EventAlignmentTimes(xds, ...
        target_dirs(jj), target_centers(jj), event);
    [avg_hists_spikes{jj}] = Avg_Hist_Spikes(xds, unit_name, Alignment_Times);
end

%% Basic Settings, some variable extractions, & definitions

% Pull the binning paramaters
[Bin_Params] = Binning_Parameters;

% Time before & after the event
before_event = Bin_Params.before_event;
after_event = Bin_Params.after_event;

% Binning information
bin_size = Bin_Params.bin_size; % Time (sec.)

% Window to calculate max firing rate
half_window_length = Bin_Params.half_window_length; % Time (sec.)

if ~contains(event, 'window')
    max_fr_time = 0;
end

if contains(event, 'goCue') || contains(event, 'force_onset')
    % Define the window for the baseline phase
    time_before_gocue = 0.4;
elseif contains(event, 'end')
    % Define the window for the movement phase
    time_before_end = xds.meta.TgtHold;
end

% Font & plotting specifications
[Plot_Params] = Plot_Parameters;

%% X-axis
spike_time = (-before_event:bin_size:after_event);
spike_time = spike_time(1:end-1) + bin_size/2;
% Removing the first and last bins (to remove the histcounts error)
spike_time(:,1) = [];
spike_time(:,length(spike_time)) = [];

%% Plot the average firing rate
for ii = 1:length(avg_hists_spikes)
    
    Firing_Rate_figure = figure;
    Firing_Rate_figure.Position = [300 300 Plot_Params.fig_size Plot_Params.fig_size / 2];
    hold on

    plot(spike_time, avg_hists_spikes{ii}, 'LineWidth', Plot_Params.mean_line_width)

    %% Set the title, labels, axes, & plot lines indicating alignment

    % Titling the rasters
    if strcmp(event, 'trial_goCue')
        Fig_Title = strcat(char(xds.unit_names(N)), {' '}, 'aligned to trial gocue:');
    else
        if contains(event, 'window')
            temp_event = strrep(event, 'window_', '');
        else
            temp_event = event;
        end
        event_title = strcat('aligned to', {' '}, strrep(temp_event, '_', {' '}), ':');
        Fig_Title = strcat(char(unit), {' '}, event_title, {' '}, num2str(target_dirs(ii)), ...
            '°, TgtCenter at', {' '}, num2str(target_centers(ii)));
    end
    if contains(xds.meta.rawFileName, 'Pre')
        Fig_Title = strcat(Fig_Title, {' '}, '(Morning)');
    end
    if contains(xds.meta.rawFileName, 'Post')
        Fig_Title = strcat(Fig_Title, {' '}, '(Afternoon)');
    end
    title(Fig_Title, 'FontSize', Plot_Params.title_font_size)

    % Axis Labels
    ylabel('Firing Rate (Hz)', 'FontSize', (Plot_Params.label_font_size - 5));
    xlabel('Time (sec.)', 'FontSize', Plot_Params.label_font_size);

    % Setting the x-axis limits
    if contains(event, 'goCue') || contains(event, 'onset')
        xlim([-1, after_event]);
    elseif contains(event, 'end')
        xlim([-before_event, 1]);
    else
        xlim([-before_event, after_event]);
    end
    % Setting the y-axis limits
    ylim([0, max_YLims])
    ylims = ylim;

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
        line([max_fr_time(ii) - half_window_length, max_fr_time(ii) - half_window_length], ... 
            [ylims(1), ylims(2)], 'linewidth', Plot_Params.mean_line_width, ...
            'color',[.5 0 .5],'linestyle','--');
        % Dotted purple line indicating end of measured window
        line([max_fr_time(ii) + half_window_length, max_fr_time(ii) + half_window_length], ... 
            [ylims(1), ylims(2)], 'linewidth', Plot_Params.mean_line_width, ...
            'color',[.5 0 .5],'linestyle','--');
    elseif ~contains(event, 'trial_gocue') && ~contains(event, 'trial_end')
        % Dotted red line indicating beginning of measured window
        line([-0.1, -0.1], [ylims(1), ylims(2)], ...
            'Linewidth', Plot_Params.mean_line_width, 'Color', 'r', 'Linestyle','--');
        % Dotted red line indicating end of measured window
        line([0.1, 0.1], [ylims(1), ylims(2)], ...
            'Linewidth', Plot_Params.mean_line_width, 'Color', 'r', 'Linestyle','--');
    end

    % Only label every other tick
    figure_axes = gca;
    figure_axes.LineWidth = Plot_Params.axis_line_width;
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
    set(figure_axes,'FontName', Plot_Params.font_name);

    %% Save the file if selected
    Save_Figs(Fig_Title, Save_File)

end % End of target direction loop




