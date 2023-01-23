function [raster_video] = RasterPlot_Record_Video

%% Display the function being used & load the relevant files

clear
clc
close all

disp('Record Raster Plot:');

% Select The Date & Task To Analyze
Date = '20211020';
Task = 'WS';
% Do You Want To Process The XDS File? (1 = Yes; 0 = No)
Process_XDS = 1;

[~, xds] = Load_XDS(Date, Task, Process_XDS);

unit_name = 'elec39_1';

N = strcmp(xds.unit_names, unit_name);

%% Some variable extraction & definitions

% Define the window for the baseline phase
time_before_gocue = 0.4;

raster_length = 2;

% Extract the trial directions
target_dir_idx = round(xds.trial_target_dir);
% Extract the go-cue times
gocue_time = xds.trial_gocue_time;
% Extract the trial end times
end_time = xds.trial_end_time;

% Font specifications
label_font_size = 20;

%% Removing non-numbers in the trial target directions

nan_idx_dir = isnan(target_dir_idx);
target_dir_idx(nan_idx_dir) = [];
clear nan_idx_dir

%% Indexes for rewarded trials in all directions

% Select the first direction (Start with the minimum direction value)
target_dir = unique(target_dir_idx);

% Finding the window of the movement phase
[max_float_avg_idx, bin_size, ~] = GoCueWindow(xds, unit_name);
% Window to calculate max firing rate
fr_window = (0.1 / bin_size);

%% Indexes for rewarded trials

total_rewarded_trial_idx = find((xds.trial_result == 'R') & (xds.trial_target_dir == target_dir(3)));

%% Find the number of targets in that particular direction
% Find which column holds the target centers
tgt_Center_idx = contains(xds.trial_info_table_header, 'tgtCenter');
if ~any(tgt_Center_idx)
    tgt_Center_idx = contains(xds.trial_info_table_header, 'tgtCtr');
end

% Pull the target center coordinates of each succesful trial   
tgt_cntrs = struct([]);
for ii = 1:height(total_rewarded_trial_idx)
    tgt_cntrs{ii,1} = xds.trial_info_table{total_rewarded_trial_idx(ii), tgt_Center_idx};
end
    
% Convert the centers into polar coordinates
target_centers_morn = zeros(height(total_rewarded_trial_idx), 1);
for ii = 1:height(total_rewarded_trial_idx)
    target_centers_morn(ii) = sqrt((tgt_cntrs{ii,1}(1,1))^2 + (tgt_cntrs{ii,1}(1,2))^2);
end

% Find the number of unique target centers
unique_targets_morn = unique(target_centers_morn);
    
%% Redifine the rewarded_idx according to the target center
rewarded_trial_idx = total_rewarded_trial_idx(target_centers_morn == unique_targets_morn(1));

%% Loop to extract only rewarded trials 
% Rewarded go-cues
rewarded_gocue_time = zeros(length(rewarded_trial_idx),1);
for ii = 1:length(rewarded_trial_idx)
    rewarded_gocue_time(ii) = gocue_time(rewarded_trial_idx(ii));
end
   
% Rewarded end times
rewarded_end_time = zeros(length(rewarded_trial_idx),1);
for ii = 1:length(rewarded_trial_idx)
    rewarded_end_time(ii) = end_time(rewarded_trial_idx(ii));
end
    
%% Removing non-numbers
% Remove non-numbers in rewarded go-cue's
nan_idx_gocue = find(isnan(rewarded_gocue_time));
rewarded_gocue_time(nan_idx_gocue) = [];
rewarded_end_time(nan_idx_gocue) = [];
rewarded_trial_idx(nan_idx_gocue) = [];
clear nan_idx_gocue

% Remove non-numbers in rewarded end times
nan_idx_end_time = find(isnan(rewarded_end_time));
rewarded_gocue_time(nan_idx_end_time) = [];
rewarded_end_time(nan_idx_end_time) = [];
rewarded_trial_idx(nan_idx_end_time) = [];
clear nan_idx_end_time

%% Times between events

% Find time between the go-cue and reward
gocue_to_reward = rewarded_end_time - rewarded_gocue_time;

%% Picking the timings for the events to be aligned

event_time_idx = xds.trial_gocue_time(rewarded_trial_idx);

t1 = event_time_idx - raster_length + 1;
t2 = event_time_idx + raster_length + 1;

%% Getting the spike timestamps based on the behavior timings above
spikes = xds.spikes{1, N};

aligned_spike_timing = struct([]);
for ii = 1:length(event_time_idx)
    aligned_spike_timing{ii, 1} = spikes((spikes > t1(ii)) & (spikes < t2(ii)));
end

%% Plotting peri-event rasters on the lower pannel of the the figure

figure('Position', [350 350 700 250]);
%subplot(211); % (Top Plot)
hold on

% Setting the y-axis limits
ylim([0, length(rewarded_trial_idx)+1])
ylims = ylim;
% Setting the x-axis limits
xlim([-raster_length + 1, raster_length + 1]);

xlabel('Time (sec.)', 'FontSize', label_font_size)

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
        if (aligned_spike_timing{ii, 1}(pp,1) - event_time_idx(ii)) >= gocue_to_reward(ii) && isequal(cc, 1)
            % Plot the rewarded trials as red dots
            plot(gocue_to_reward(ii), ii,... 
                'marker', '.', 'color', 'r', 'markersize', 15);
            cc = 1;
        end
        plot(aligned_spike_timing{ii, 1}(pp,1) - event_time_idx(ii), ii,... 
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




