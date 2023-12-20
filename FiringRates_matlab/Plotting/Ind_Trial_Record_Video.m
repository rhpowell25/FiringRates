function [raster_video] = Ind_Trial_Record_Video

%% Display the function being used & load the relevant files

clear
clc
close all

disp('Record Individual Trials:');

% Monkey Name
Monkey = 'Tot';
% Select the date & task to analyze (YYYYMMDD)
Date = '20230428';
Task = 'PGKG';
% Sorted or unsorted (1 vs 0)
Sorted = 1;

% Load the xds file
xds = Load_XDS(Monkey, Date, Task, Sorted, 'Morn');

% Find the unit of interest
unit_name = 'elec13_1';
[N] = Find_Unit(xds, unit_name);
unit = xds.unit_names(N);

event = 'window_trial_gocue';

max_YLims = YLimit(xds, xds, event, unit_name);

%% Remove all the NaN's
[xds] = NaN_Remover(xds);

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

% Font & plotting specifications
[Plot_Params] = Plot_Parameters;

% Binning information
bin_size = Bin_Params.bin_size; % Time (sec.)
n_bins = (after_event + before_event)/bin_size;
bin_edges = linspace(-before_event, after_event, n_bins);

% Window to calculate max firing rate
half_window_length = Bin_Params.half_window_length; % Time (sec.)

% Finding the window of the movement phase
[~, max_fr_time] = EventWindow(xds, unit_name, target_dirs(1), target_centers(1), event);
% Window to calculate max firing rate
fr_window = (0.1 / bin_size);

%% Times for rewarded trials
[rewarded_gocue_time] = GoCueAlignmentTimes(xds, target_dirs(1), target_centers(1));
[rewarded_end_time] = TrialEndAlignmentTimes(xds, target_dirs(1), target_centers(1));
[Alignment_Times] = EventAlignmentTimes(xds, target_dirs(1), target_centers(1), event);

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

% Finding the absolute timing
absolute_spike_timing = struct([]);
for ii = 1:length(rewarded_gocue_time)
    absolute_spike_timing{ii,1} = aligned_spike_timing{ii,1} - Alignment_Times(ii);
end

%% Binning & averaging the spikes
hist_spikes = zeros(length(rewarded_gocue_time), n_bins - 1);
for ii = 1:length(rewarded_gocue_time)
    [hist_spikes(ii, :), ~] = histcounts(absolute_spike_timing{ii,1}, bin_edges);
end

% Removing the first bins (for alignment)
hist_spikes(:,1) = [];

%% Plotting peri-event rasters on the lower pannel of the the figure

Raster_figure = figure;
Raster_figure.Position = [300 300 Plot_Params.fig_size Plot_Params.fig_size / 2];

for ii = 1:height(hist_spikes)

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
        raster_title = strcat(char(unit), {' '}, event_title, {' '}, num2str(target_dirs(1)), ...
            '°, TgtCenter at', {' '}, num2str(target_centers(1)));
    end
    if contains(xds.meta.rawFileName, 'Pre')
        raster_title = strcat(raster_title, {' '}, '(Morning)');
    end
    if contains(xds.meta.rawFileName, 'Post')
        raster_title = strcat(raster_title, {' '}, '(Afternoon)');
    end
    title(raster_title, 'FontSize', Plot_Params.title_font_size)
    
    % Axis Labels
    ylabel('Firing Rate (Hz)', 'FontSize', (Plot_Params.label_font_size - 5));
    xlabel('Time (sec.)', 'FontSize', Plot_Params.label_font_size);
    
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
        line([max_fr_time(1) - half_window_length, max_fr_time(1) - half_window_length], ... 
            [ylims(1), ylims(2)], 'linewidth', Plot_Params.mean_line_width, ...
            'color',[.5 0 .5],'linestyle','--');
        % Dotted purple line indicating end of measured window
        line([max_fr_time(1) + half_window_length, max_fr_time(1) + half_window_length], ... 
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
    figure_axes.LineWidth = Plot_Params.axes_line_width;
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


    plot(hist_spikes(ii, :)/bin_size)
    M(ii) = getframe(gcf);
end

%% Save the newly produced video
AVI_save_name = 'C:\Users\rhpow\Desktop\Ind_Trial_Video.mp4';
raster_video = VideoWriter(AVI_save_name, 'MPEG-4');
raster_video.FrameRate = 2; % Frames per second
open(raster_video)
writeVideo(raster_video, M);
close(raster_video);

%% Increase the playback speed

slow_raster_video = VideoReader('C:\Users\rhpow\Desktop\Ind_Trial_Video.mp4');

fast_raster_video = VideoWriter('Fast_Ind_Trial_Video', 'MPEG-4');

fast_raster_video.FrameRate = 2; % Frames per second
open(fast_raster_video)

while hasFrame(slow_raster_video)
    k = readFrame(slow_raster_video);

    fast_raster_video.writeVideo(k);
end

close(fast_raster_video)




