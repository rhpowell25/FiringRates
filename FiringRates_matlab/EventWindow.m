function [avg_hists_spikes, max_fr_time, bin_size] = EventWindow(xds, unit_name, target_dir, target_center, event)

%% Find the meta info to load the output excel table

% Load the excel file
if ~isnan(unit_name)
    if ~ischar(unit_name)
    
        [xds_output] = Find_Excel(xds);
    
        % Find the unit of interest
        try
            unit = xds_output.unit_names(unit_name);
            % Identify the index of the unit
            N = find(strcmp(xds.unit_names, unit));
        catch
            N = [];
        end
    
    else
        N = find(strcmp(xds.unit_names, unit_name));
    end
else
    N = [];
end

%% End the function with NaN output variables if the unit doesnt exist

if ~any(N)
    fprintf('%s does not exist \n', unit_name);
    avg_hists_spikes = NaN;
    max_fr_time = NaN;
    bin_size = NaN;
    return
end

%% Basic settings, some variable extractions, & definitions

% Extract all the spikes of the unit
spikes = xds.spikes{1, N};

% Time before & after cursor onset
before_event = 3.0;
after_event = 3.0;

% Bin size & number of bins
bin_size = 0.04;
n_bins = round((after_event + before_event)/bin_size);

% Window to calculate max firing rate
window_size = 4; % Bins
step_size = 1; % Bins

%% Times for rewarded trials

[rewarded_gocue_time] = EventAlignmentTimes(xds, target_dir, target_center, 'trial_gocue');
[rewarded_end_time] = EventAlignmentTimes(xds, target_dir, target_center, 'trial_end');
[Alignment_Times] = EventAlignmentTimes(xds, target_dir, target_center, event);

%% Getting the spike timestamps based on the behavior timings above

aligned_spike_timing = struct([]);
for ii = 1:length(rewarded_gocue_time)
    aligned_spike_timing{ii, 1} = spikes((spikes > (Alignment_Times(ii) - before_event)) & ... 
        (spikes < (Alignment_Times(ii) + after_event)));
end

% Finding the absolute timing
absolute_spike_timing = struct([]);
for ii = 1:length(rewarded_gocue_time)
    absolute_spike_timing{ii,1} = aligned_spike_timing{ii,1} - rewarded_gocue_time(ii);
end

%% Binning & averaging the spikes
hist_spikes = zeros(length(rewarded_gocue_time), n_bins);
for ii = 1:length(rewarded_gocue_time)
    [hist_spikes(ii, :), ~] = histcounts(absolute_spike_timing{ii,1}, n_bins);
end

% Removing the first and last bins (to remove the histcounts error)
hist_spikes(:,1) = [];
hist_spikes(:,width(hist_spikes)) = [];

% Averaging the hist spikes
avg_hists_spikes = mean(hist_spikes, 1)/bin_size;

%% Find the trial lengths
gocue_to_event = Alignment_Times - rewarded_gocue_time;
event_to_end = rewarded_end_time - Alignment_Times;

%% Find the 5th percentile of the trial go cue
max_gocue_to_event = prctile(gocue_to_event, 5);

%% Find the 90th percentile of the trial end
max_event_to_end = prctile(event_to_end, 90);

%% Convert the times to fit the bins
max_gocue_idx = round(max_gocue_to_event / bin_size);

if contains(event, 'gocue') % Start moving average 5 indices (0.2 sec) after the gocue
    max_gocue_idx = -5;
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
        end - ((window_size / bin_size)/2));
end

[float_avg, ~, array_idxs] = Sliding_Window(array, window_size, step_size);

%% Find where the highest average was calculated
max_float_avg = max(float_avg);
max_fr_idx = find(float_avg == max_float_avg);

max_array_idxs = array_idxs{max_fr_idx(1)};

center_max_fr_idx = max_array_idxs(ceil(end/2)) + length(avg_hists_spikes) / 2 - max_gocue_idx - 1;

%% Print the maximum firing rate in that window
fprintf("The max firing rate is %0.1f Hz \n", max_float_avg);

%% Display the measured time window
max_fr_time = (-before_event) + (center_max_fr_idx*bin_size);
fprintf("The movement phase window is centered on %0.2f seconds \n", max_fr_time);























