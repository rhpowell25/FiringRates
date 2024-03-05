function [avg_hists_spikes] = Avg_Hist_Spikes(xds, unit_name, Alignment_Times)

%% Find the unit of interest
[N] = Find_Unit(xds, unit_name);

%% Catch possible sources of error
% If there is no unit of that name
if isempty(N)
    fprintf('%s does not exist \n', unit_name);
    avg_hists_spikes = NaN;
    return
end

%% Basic settings, some variable extractions, & definitions

% Extract all the spikes of the unit
spikes = xds.spikes{1, N};

% Pull the binning paramaters
[Bin_Params] = Binning_Parameters;

% Time before & after the event
before_event = Bin_Params.before_event;
after_event = Bin_Params.after_event;

% Binning information
bin_size = Bin_Params.bin_size; % Time (sec.)
n_bins = (after_event + before_event)/bin_size;
bin_edges = linspace(-before_event, after_event, n_bins);

%% Getting the spike timestamps based on the behavior timings above

aligned_spike_timing = struct([]);
for ii = 1:length(Alignment_Times)
    aligned_spike_timing{ii, 1} = spikes((spikes > (Alignment_Times(ii) - before_event)) & ... 
        (spikes < (Alignment_Times(ii) + after_event)));
end

% Finding the absolute timing
absolute_spike_timing = struct([]);
for ii = 1:length(Alignment_Times)
    absolute_spike_timing{ii,1} = aligned_spike_timing{ii,1} - Alignment_Times(ii);
end

%% Binning & averaging the spikes
%figure
%hold on
hist_spikes = zeros(length(Alignment_Times), n_bins - 1);
for ii = 1:length(Alignment_Times)
    [hist_spikes(ii, :), ~] = histcounts(absolute_spike_timing{ii,1}, bin_edges);
    %plot(hist_spikes(ii, :)/bin_size)
end

% Removing the first bins (for alignment)
hist_spikes(:,1) = [];

% Averaging the hist spikes
avg_hists_spikes = mean(hist_spikes, 1)/bin_size;























