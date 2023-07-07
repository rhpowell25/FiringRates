function RasterPlot(xds, unit_name, event, heat_map, Save_Figs)

%% Find the unit of interest
[N] = Find_Unit(xds, unit_name);

%% End the function with NaN output variables if the unit doesnt exist
if isempty(N)
    fprintf('%s does not exist \n', unit_name);
    return
end

%% Basic settings, some variable extractions, & definitions

% Extract all the spikes of the unit
spikes = xds.spikes{1, N};

% Define the window for the baseline phase
time_before_gocue = 0.4;
% Define the window for the movement phase
if contains(event, 'trial_end')
    time_before_end = xds.meta.TgtHold;
end

% Pull the binning paramaters
[Bin_Params] = Binning_Parameters;

% Time before & after the event
before_event = Bin_Params.before_event;
after_event = Bin_Params.after_event;

% Extract the target directions & centers
[target_dirs, target_centers] = Identify_Targets(xds);

% Font specifications
label_font_size = 20;
title_font_size = 15;
font_name = 'Arial';
figure_width = 750;
figure_height = 250;

%% Indexes for rewarded trials in all directions
% Counts the number of directions used
num_dir = length(target_dirs);

%% Begin the loop through all directions
for jj = 1:num_dir

    %% Times for rewarded trials
    if strcmp(event, 'trial_gocue')
        [rewarded_gocue_time] = GoCueAlignmentTimes(xds, NaN, NaN);
        [rewarded_end_time] = TrialEndAlignmentTimes(xds, NaN, NaN);
        [Alignment_Times] = EventAlignmentTimes(xds, NaN, NaN, event);
    else
        [rewarded_gocue_time] = GoCueAlignmentTimes(xds, target_dirs(jj), target_centers(jj));
        [rewarded_end_time] = TrialEndAlignmentTimes(xds, target_dirs(jj), target_centers(jj));
        [Alignment_Times] = EventAlignmentTimes(xds, target_dirs(jj), target_centers(jj), event);
    end

    %% Time period for peak firing rate
    if contains(event, 'window')
        % Run the preferred direction window function
        [~, max_fr_time] = EventWindow(xds, unit_name, target_dirs(jj), target_centers(jj), event);
        half_window_length = Bin_Params.half_window_length; % Time (sec.)
        window_color = [.5 0 .5];
    else
        bin_size = Bin_Params.bin_size; % Time (sec.)
        max_fr_time = 0;
        window_color = 'r';
    end

    %% Times between events
    % Find time between the go-cue and reward
    gocue_to_event = Alignment_Times - rewarded_gocue_time;
    event_to_end = rewarded_end_time - Alignment_Times;

    %% Getting the spike timestamps based on the behavior timings above

    aligned_spike_timing = struct([]);
    for ii = 1:length(rewarded_gocue_time)
        aligned_spike_timing{ii, 1} = spikes((spikes > (Alignment_Times(ii) - before_event)) & ... 
            (spikes < (Alignment_Times(ii) + after_event)));
    end

    %% If Heat Map is selected
    if isequal(heat_map, 1)
    
        %% Binning & averaging the spikes
        n_bins = round((before_event + after_event) / bin_size);

        hist_spikes = struct([]);
        for ii = 1:length(rewarded_gocue_time)
            [hist_spikes{ii, 1}, ~] = histcounts(aligned_spike_timing{ii, 1}, n_bins);
        end

        % Finding the firing rates of the hist spikes
        fr_hists_spikes = struct([]);
        for ii = 1:length(rewarded_gocue_time)
            fr_hists_spikes{ii,1} = hist_spikes{ii,1} / bin_size;
        end

        %% Finding the maximum firing rate of each unit to normalize
        max_fr_per_trial = zeros(length(fr_hists_spikes),1);
        for ii = 1:length(max_fr_per_trial)
            max_fr_per_trial(ii) = max(fr_hists_spikes{ii,1});
        end

        %% Normalizing the firing rate of each unit
        norm_fr_hists_spikes = fr_hists_spikes;
        for ii = 1:length(rewarded_gocue_time)
            norm_fr_hists_spikes{ii,1} = fr_hists_spikes{ii,1} / max_fr_per_trial(ii);
        end

    end
    
    %% Plotting peri-event rasters

    Raster_figure = figure;
    Raster_figure.Position = [300 300 figure_width figure_height];
    hold on

    if isequal(heat_map, 0)
        for ii = 1:length(aligned_spike_timing)
            % The main raster plot
            plot(aligned_spike_timing{ii, 1} - Alignment_Times(ii), ...
                ones(1, length(aligned_spike_timing{ii, 1}))*ii,... 
                'Marker', '.', 'Color', 'k', 'Markersize', 3, 'Linestyle', 'none');
            if ~contains(event, 'gocue')
                % Plot the go-cues as dark green dots
                plot(-gocue_to_event(ii), ii, 'Marker', '.', 'Color', [0 0.5 0], 'Markersize', 15);
            end
            if ~contains(event, 'end')
                % Plot the trial ends as red dots
                plot(event_to_end(ii), ii, 'Marker', '.', 'Color', 'r', 'Markersize', 15);
            end
        end
    end

    if isequal(heat_map, 1)
        colormap('turbo');
        for ii = 1:length(aligned_spike_timing)
            % Define the time axis
            time_axis = (-before_event:bin_size:after_event);
            if length(time_axis) > length(norm_fr_hists_spikes{ii,1})
                time_axis(end) = [];
            end
            % The main raster plot
            imagesc(time_axis, ii, norm_fr_hists_spikes{ii,1});
        end
    end

    %% Plotting additions

    % Setting the y-axis limits
    ylim([0, length(rewarded_gocue_time)+1])
    ylims = ylim;

    % Setting the x-axis limits
    if contains(event, 'gocue') || contains(event, 'onset')
        xlim([-1, after_event]);
    elseif contains(event, 'end')
        xlim([-before_event, 1]);
    else
        xlim([-before_event, after_event]);
    end

    if contains(event, 'gocue')
        % Dotted green line indicating beginning of measured window
        line([-time_before_gocue, -time_before_gocue], [ylims(1), ylims(2)], ...
            'linewidth',2,'color',[0 0.5 0],'linestyle','--');
        % Solid green line indicating the aligned time
        line([0, 0], [ylims(1), ylims(2)], ...
            'linewidth', 2, 'color', [0 0.5 0]);
    end
    if contains(event, 'trial_end')
        % Solid red line indicating the aligned time
        line([0, 0], [ylims(1), ylims(2)], ...
            'linewidth', 2, 'color', 'r');
        % Dotted red line indicating beginning of measured window
        line([-time_before_end, -time_before_end], [ylims(1), ylims(2)], ...
            'linewidth',2,'color','r','linestyle','--');
    end

    if ~strcmp(event, 'trial_gocue') && ~strcmp(event, 'trial_end')
        % Dotted line indicating beginning of measured window
        line([max_fr_time - half_window_length, max_fr_time - half_window_length], ... 
            [ylims(1), ylims(2)], 'linewidth', 2, 'Color', window_color, 'Linestyle','--');
        % Dotted line indicating end of measured window
        line([max_fr_time + half_window_length, max_fr_time + half_window_length], ... 
            [ylims(1), ylims(2)], 'linewidth', 2, 'Color', window_color, 'Linestyle','--');
    end

    % Remove the y-axis
    yticks([])

    % Titling the rasters
    if strcmp(event, 'trial_gocue')
        raster_title = strcat(char(xds.unit_names(N)), {' '}, 'aligned to trial gocue:');
    else
        if contains(event, 'window')
            temp_event = strrep(event, 'window_', '');
        else
            temp_event = event;
        end
        event_title = strcat('aligned to', {' '}, strrep(temp_event, '_', {' '}), ':');
        raster_title = strcat(char(xds.unit_names(N)), {' '}, event_title, {' '}, num2str(target_dirs(jj)), ...
            '°, TgtCenter at', {' '}, num2str(target_centers(jj)));
    end
    if contains(xds.meta.rawFileName, 'Pre')
        raster_title = strcat(raster_title, {' '}, '(Morning)');
    end
    if contains(xds.meta.rawFileName, 'Post')
        raster_title = strcat(raster_title, {' '}, '(Afternoon)');
    end
    title(raster_title, 'FontSize', title_font_size)

    xlabel('Time (sec.)', 'FontSize', label_font_size)

    % Only label every other tick
    figure_axes = gca;
    x_labels = string(figure_axes.XAxis.TickLabels);
    x_labels(2:2:end) = NaN;
    figure_axes.XAxis.TickLabels = x_labels;
    % Set ticks to outside
    set(figure_axes,'TickDir','out');
    % Remove the top and right tick marks
    set(figure_axes,'box','off')
    % Set The Font
    set(figure_axes,'fontname', font_name);

    % End the event after one loop if showing baseline firing rate
    if strcmp(event, 'trial_gocue')
        return
    end

end % End of target loop

%% Define the save directory & save the figures
if ~isequal(Save_Figs, 0)
    save_dir = 'C:\Users\rhpow\Desktop\';
    for ii = 1:length(findobj('type','figure'))
        fig_info = get(gca,'title');
        fig_title = get(fig_info, 'string');
        if isempty(fig_title)
            fig_info = sgt;
            fig_title = get(fig_info, 'string');
        end
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



