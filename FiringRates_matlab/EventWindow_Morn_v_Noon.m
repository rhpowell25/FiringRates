function [pertrial_mpfr_morn, pertrial_mpfr_noon, max_fr_time] = ...
    EventWindow_Morn_v_Noon(xds_morn, xds_noon, unit_name, target_dir, target_center, event)

%% Find the unit of interest
[N_morn] = Find_Unit(xds_morn, unit_name);
[N_noon] = Find_Unit(xds_noon, unit_name);

%% Basic settings, some variable extractions, & definitions

% Extract all the spikes of the unit
spikes_morn = xds_morn.spikes{1, N_morn};
spikes_noon = xds_noon.spikes{1, N_noon};

% Pull the binning paramaters
[Bin_Params] = Binning_Parameters;
% Window to calculate max firing rate
half_window_length = Bin_Params.half_window_length; % Time (sec.)

%% Find where the highest average was calculated
% Morning
[~, max_fr_time_morn] = ...
    EventWindow(xds_morn, unit_name, target_dir, target_center, event);
% Afternoon
[~, max_fr_time_noon] = ...
    EventWindow(xds_noon, unit_name, target_dir, target_center, event);

%% Times for rewarded trials
% Morning
[Alignment_Times_morn] = EventAlignmentTimes(xds_morn, target_dir, target_center, event);
% Afternoon
[Alignment_Times_noon] = EventAlignmentTimes(xds_noon, target_dir, target_center, event);

%% Peak firing rate
% Morning
pertrial_mpfr_morn = struct([]);
for ii = 1:length(Alignment_Times_morn)
    t_start = Alignment_Times_morn(ii) + max_fr_time_morn - half_window_length;
    t_end = Alignment_Times_morn(ii) + max_fr_time_morn + half_window_length;
    pertrial_mpfr_morn{1,1}(ii,1) = length(find((spikes_morn >= t_start) & ...
            (spikes_morn <= t_end))) / (2*half_window_length);
end
% Afternoon
pertrial_mpfr_noon = struct([]);
for ii = 1:length(Alignment_Times_noon)
    t_start = Alignment_Times_noon(ii) + max_fr_time_noon - half_window_length;
    t_end = Alignment_Times_noon(ii) + max_fr_time_noon + half_window_length;
    pertrial_mpfr_noon{1,1}(ii,1) = length(find((spikes_noon >= t_start) & ...
            (spikes_noon <= t_end))) / (2*half_window_length);
end

%% Defining the output variable
% Peak firing rate
mp_fr_morn = mean(pertrial_mpfr_morn{1,1});
mp_fr_noon = mean(pertrial_mpfr_noon{1,1});

% If morning is larger
if mp_fr_morn > mp_fr_noon
    max_fr_time = max_fr_time_morn;
    pertrial_mpfr_noon = struct([]);
    % Recalculate the afternoon
    for ii = 1:length(Alignment_Times_noon)
        t_start = Alignment_Times_noon(ii) + max_fr_time - half_window_length;
        t_end = Alignment_Times_noon(ii) + max_fr_time + half_window_length;
        pertrial_mpfr_noon{1,1}(ii,1) = length(find((spikes_noon >= t_start) & ...
                (spikes_noon <= t_end))) / (2*half_window_length);
    end
end

% If afternoon is larger
if mp_fr_noon > mp_fr_morn
    max_fr_time = max_fr_time_noon;
    % Recalculate the morning
    pertrial_mpfr_morn = struct([]);
    for ii = 1:length(Alignment_Times_morn)
        t_start = Alignment_Times_morn(ii) + max_fr_time - half_window_length;
        t_end = Alignment_Times_morn(ii) + max_fr_time + half_window_length;
        pertrial_mpfr_morn{1,1}(ii,1) = length(find((spikes_morn >= t_start) & ...
                (spikes_morn <= t_end))) / (2*half_window_length);
    end
end

% If they are the same
if mp_fr_morn == mp_fr_noon && max_fr_time_morn == max_fr_time_noon
    max_fr_time = max_fr_time_morn;
end

















