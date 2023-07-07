function [TgtHold_fr, std_TgtHold, err_TgtHold, all_trials_TgtHold_fr] = TgtHoldFiringRate(xds, unit_name)

%% Find the unit of interest
[N] = Find_Unit(xds, unit_name);

%% Catch possible sources of error
% If there is no unit of that name
if isempty(N)
    fprintf('%s does not exist \n', unit_name);
    TgtHold_fr = NaN;
    std_TgtHold = NaN;
    err_TgtHold = NaN;
    all_trials_TgtHold_fr = NaN;
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
    TgtHold_fr = NaN(length(target_dirs), 1);
    std_TgtHold = NaN(length(target_dirs), 1);
    err_TgtHold = NaN(length(target_dirs), 1);
    all_trials_TgtHold_fr = NaN(length(target_dirs), 1);
    return
end

%% Indexes for rewarded trials in all directions
% Counts the number of directions used
num_dirs = length(target_dirs);

%% Begin the loop through all directions
for jj = 1:num_dirs
    
    %% Times for rewarded trials
    [rewarded_end_time] = EventAlignmentTimes(xds, target_dirs(jj), target_centers(jj), 'trial_end');
    
    %% Define the output variables
    if jj == 1
        TgtHold_fr = zeros(num_dirs, 1);
        std_TgtHold = zeros(num_dirs, 1);
        err_TgtHold = zeros(num_dirs, 1);
        all_trials_TgtHold_fr = struct([]);
    end

    %% TgtHold Phase Firing Rate
    for ii = 1:length(rewarded_end_time)
        t_start = rewarded_end_time(ii) - time_before_end;
        t_end = rewarded_end_time(ii);
        all_trials_TgtHold_fr{jj,1}(ii,1) = length(find((spikes >= t_start) & ...
                (spikes <= t_end))) / (t_end - t_start);
    end
        
    %% Defining the output variables

    % TgtHold phase firing rate
    TgtHold_fr(jj,1) = mean(all_trials_TgtHold_fr{jj,1});
    % Standard Deviation
    std_TgtHold(jj,1) = std(all_trials_TgtHold_fr{jj,1});
    % Standard Error
    err_TgtHold(jj,1) = std_TgtHold(jj,1) / sqrt(length(all_trials_TgtHold_fr{jj,1}));
    
end % End of target loop



