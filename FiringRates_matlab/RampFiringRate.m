function [ramp_fr, std_ramp, err_ramp, all_trials_ramp_fr] = RampFiringRate(xds, unit_name)

%% Find the unit of interest
[N] = Find_Unit(xds, unit_name);

%% Catch possible sources of error
% If there is no unit of that name
if isempty(N)
    fprintf('%s does not exist \n', unit_name);
    ramp_fr = NaN;
    std_ramp = NaN;
    err_ramp = NaN;
    all_trials_ramp_fr = NaN;
    return
end

%% Basic settings, some variable extractions, & definitions

% Extract all the spikes of the unit
spikes = xds.spikes{1, N};

% Extract the target directions & centers
[target_dirs, target_centers] = Identify_Targets(xds);

% Define period before end to measure
try
    time_before_end = xds.meta.TgtHold;
catch
    disp('XDS file does not have TgtHold')
    ramp_fr = NaN(length(target_dirs), 1);
    std_ramp = NaN(length(target_dirs), 1);
    err_ramp = NaN(length(target_dirs), 1);
    all_trials_ramp_fr = struct([NaN(length(target_dirs), 1)]);
    return
end

%% Indexes for rewarded trials in all directions
% Counts the number of directions used
num_dirs = length(target_dirs);

%% Begin the loop through all directions
for jj = 1:num_dirs
    
    %% Times for rewarded trials
    [rewarded_task_onset_time] = EventAlignmentTimes(xds, target_dirs(jj), target_centers(jj), 'task_onset');
    [rewarded_end_time] = EventAlignmentTimes(xds, target_dirs(jj), target_centers(jj), 'trial_end');
    
    %% Define the output variables
    if jj == 1
        ramp_fr = zeros(num_dirs, 1);
        all_trials_ramp_fr = struct([]);
        std_ramp = zeros(num_dirs, 1);
        err_ramp = zeros(num_dirs, 1);
    end

    %% Ramp Phase Firing Rate
    for ii = 1:length(rewarded_task_onset_time)
        t_start = rewarded_task_onset_time(ii);
        t_end = rewarded_end_time(ii) - time_before_end;
        all_trials_ramp_fr{jj,1}(ii,1) = length(find((spikes >= t_start) & ...
                (spikes <= t_end))) / (t_end - t_start);
    end
        
    %% Defining the output variables

    % Ramp phase firing rate
    ramp_fr(jj,1) = mean(all_trials_ramp_fr{jj,1});
    % Standard Deviation
    std_ramp(jj,1) = std(all_trials_ramp_fr{jj,1});
    % Standard Error
    err_ramp(jj,1) = std_ramp(jj,1) / sqrt(length(all_trials_ramp_fr{jj,1}));
    
end % End of target loop



