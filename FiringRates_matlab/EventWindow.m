function [pertrial_mpfr, max_fr_time] = ...
    EventWindow(xds, unit_name, target_dir, target_center, event)

%% Find the unit of interest
[N] = Find_Unit(xds, unit_name);

%% Catch possible sources of error
% If there is no unit of that name
if isempty(N)
    fprintf('%s does not exist \n', unit_name);
    pertrial_mpfr = NaN;
    max_fr_time = NaN;
    return
end

%% Basic settings, some variable extractions, & definitions

% Extract all the spikes of the unit
spikes = xds.spikes{1, N};

% Pull the binning paramaters
[Bin_Params] = Binning_Parameters;
% Window to calculate the max firing rate
half_window_length = Bin_Params.half_window_length; % Time (sec.)

% Time before & after the event
before_event = Bin_Params.before_event;

% Binning information
bin_size = Bin_Params.bin_size; % Time (sec.)

% Window to calculate max firing rate
half_window_size = Bin_Params.half_window_size; % Bins
%half_window_length = Bin_Params.half_window_length;
step_size = Bin_Params.step_size; % Bins

%% Times for rewarded trials

[rewarded_gocue_time] = EventAlignmentTimes(xds, target_dir, target_center, 'trial_goCue');
[rewarded_end_time] = EventAlignmentTimes(xds, target_dir, target_center, 'trial_end');
[Alignment_Times] = EventAlignmentTimes(xds, target_dir, target_center, event);

%% Binning & averaging the spikes

[avg_hists_spikes] = Avg_Hist_Spikes(xds, unit_name, Alignment_Times);

%% Find the trial lengths
gocue_to_event = Alignment_Times - rewarded_gocue_time;
event_to_end = rewarded_end_time - Alignment_Times;

%% Find the 5th percentile of the trial go cue
max_gocue_to_event = prctile(gocue_to_event, 5);

%% Find the 90th percentile of the trial end
max_event_to_end = prctile(event_to_end, 90);

%% Convert the times to fit the bins
max_gocue_idx = round(max_gocue_to_event / bin_size);

% Start 0.2 seconds after trial gocue
if strcmp(event, 'window_trial_gocue')
    max_gocue_idx = -(0.2 / bin_size);
end

max_end_idx = round(max_event_to_end / bin_size);

%% Calculate the floating average
% This array starts after the 5th percentile go-cue   
% and ends after the 90th percentile trial end

try
    array = avg_hists_spikes(length(avg_hists_spikes) / 2 - max_gocue_idx: ...
        length(avg_hists_spikes) / 2 + max_end_idx);
catch
    array = avg_hists_spikes(length(avg_hists_spikes) / 2 - max_gocue_idx: ...
        end - half_window_size);
end
[float_avg, ~, array_idxs] = Sliding_Window(array, half_window_size, step_size);

%% Find where the highest average was calculated
max_float_avg = max(float_avg);
max_fr_idx = find(float_avg == max_float_avg);

max_array_idxs = array_idxs{max_fr_idx(1)};

center_max_fr_idx = max_array_idxs(ceil(end/2)) + length(avg_hists_spikes) / 2 - max_gocue_idx - 1;

%% Print the maximum firing rate in that window
fprintf("The max firing rate is %0.1f Hz \n", max_float_avg);

%% Display the measured time window & calculate the per trial firing rate
max_fr_time = (-before_event) + (center_max_fr_idx*bin_size);

% Calculate the per trial firing rate
for ii = 1:length(Alignment_Times)
    t_start = Alignment_Times(ii) + max_fr_time - half_window_length;
    t_end = Alignment_Times(ii) + max_fr_time + half_window_length;
    pertrial_mpfr{1,1}(ii,1) = length(find((spikes >= t_start) & ...
            (spikes <= t_end))) / (2*half_window_length);
end

fprintf("The movement phase window is centered on %0.2f seconds \n", max_fr_time);























