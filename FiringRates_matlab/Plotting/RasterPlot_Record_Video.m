function [raster_video] = RasterPlot_Record_Video

%% Display the function being used & load the relevant files

clear
clc
close all

disp('Record Raster Plot:');

% Monkey Name
Monkey = 'Pop';

% Select The Date & Task To Analyze
Date = '20211020';
Task = 'WS';
% Sorted or unsorted (1 vs 0)
Sorted = 1;

% Load the xds files
xds = Load_XDS(Monkey, Date, Task, Sorted, 'Morn');
xds_noon = Load_XDS(Monkey, Date, Task, Sorted, 'Noon');

% Process the xds files
Match_The_Targets = 0;
[xds, ~] = Process_XDS(xds, xds_noon, Match_The_Targets);

unit_name = 'elec39_1';

% Find the unit of interest
[N] = Find_Unit(xds, unit_name);

%% Basic settings, some variable extractions, & definitions

event = 'window_trial_gocue';

% Extract all the spikes of the unit
spikes = xds.spikes{1, N};

% Define the window for the baseline phase
time_before_gocue = 0.4;

raster_length = 2;

% Extract the target directions & centers
[target_dirs, target_centers] = Identify_Targets(xds);

% Font & plotting specifications
[Plot_Params] = Plot_Parameters;

%% Indexes for rewarded trials in all directions

% Finding the window of the movement phase
[max_float_avg_idx, bin_size, ~] = GoCueWindow(xds, unit_name);
% Window to calculate max firing rate
fr_window = (0.1 / bin_size);

%% Times for rewarded trials
[rewarded_gocue_time] = GoCueAlignmentTimes(xds, target_dirs(3), target_centers(3));
[rewarded_end_time] = TrialEndAlignmentTimes(xds, target_dirs(3), target_centers(3));
[Alignment_Times] = EventAlignmentTimes(xds, target_dirs(3), target_centers(3), event);

%% Times between events

% Find time between the go-cue and reward
gocue_to_reward = rewarded_end_time - rewarded_gocue_time;

%% Getting the spike timestamps based on the behavior timings above

aligned_spike_timing = struct([]);
for ii = 1:length(rewarded_gocue_time)
    aligned_spike_timing{ii, 1} = spikes((spikes > (Alignment_Times(ii) - before_event)) & ... 
        (spikes < (Alignment_Times(ii) + after_event)));
end

%% Plotting peri-event rasters on the lower pannel of the the figure

figure('Position', [350 350 700 250]);
%subplot(211); % (Top Plot)
hold on

% Setting the y-axis limits
ylim([0, length(Alignment_Times)+1])
ylims = ylim;
% Setting the x-axis limits
xlim([-raster_length + 1, raster_length + 1]);

xlabel('Time (sec.)', 'FontSize', Plot_Params.label_font_size)

% Remove the y-axis
yticks([])

% Dotted green line indicating beginning of measured window
line([-time_before_gocue, -time_before_gocue], [ylims(1), ylims(2)], ...
    'linewidth',2,'color',[0 0.5 0],'linestyle','--');
% Solid green line indicating the aligned time
line([0, 0], [ylims(1), ylims(2)], ...
    'linewidth', 2, 'color', [0 0.5 0]);

mm = 1;
for ii = 1:length(aligned_spike_timing)
    cc = 1;
    % The main raster plot
    for pp = 1:length(aligned_spike_timing{ii,1})
        if (aligned_spike_timing{ii, 1}(pp,1) - Alignment_Times(ii)) >= gocue_to_reward(ii) && isequal(cc, 1)
            % Plot the rewarded trials as red dots
            plot(gocue_to_reward(ii), ii,... 
                'marker', '.', 'color', 'r', 'markersize', 15);
            cc = 1;
        end
        plot(aligned_spike_timing{ii, 1}(pp,1) - Alignment_Times(ii), ii,... 
            'marker', '.', 'color', 'k', 'markersize', 3, 'linestyle', 'none');
        M(mm) = getframe(gcf);
        mm = mm + 1;
    end
end

% Dotted purple line indicating beginning of measured window
line([-raster_length/2 + (max_float_avg_idx*bin_size - fr_window*bin_size), ... 
    -raster_length/2 + (max_float_avg_idx*bin_size - fr_window*bin_size)], ... 
    [ylims(1), ylims(2)], 'linewidth',2,'color',[.5 0 .5],'linestyle','--');
% Dotted purple line indicating end of measured window
line([-raster_length/2 + (max_float_avg_idx*bin_size + fr_window*bin_size), ...
    -raster_length/2 + (max_float_avg_idx*bin_size + fr_window*bin_size)], ... 
    [ylims(1), ylims(2)], 'linewidth',2,'color',[.5 0 .5],'linestyle','--');

M(mm) = getframe(gcf);

%% Save the newly produced video
AVI_save_name = 'C:\Users\rhpow\Documents\MATLAB\Raster_Plot_Video.mp4';
raster_video = VideoWriter(AVI_save_name, 'MPEG-4');
raster_video.FrameRate = 75; % Frames per second
open(raster_video)
writeVideo(raster_video, M);
close(raster_video);

%% Increase the playback speed

slow_raster_video = VideoReader('C:\Users\rhpow\Documents\MATLAB\Raster_Plot_Video.mp4');

fast_raster_video = VideoWriter('Fast_Raster_Video', 'MPEG-4');

fast_raster_video.FrameRate = 140; % Frames per second
open(fast_raster_video)

while hasFrame(slow_raster_video)
    k = readFrame(slow_raster_video);

    fast_raster_video.writeVideo(k);
end

close(fast_raster_video)




