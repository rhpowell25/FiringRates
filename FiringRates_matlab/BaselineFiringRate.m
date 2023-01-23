function [bs_fr, std_bs, all_trials_bs_fr] = ...
    BaselineFiringRate(xds, unit_name)

%% Load the excel file
if ~ischar(unit_name)

    [xds_output] = Find_Excel(xds);

    %% Find the unit of interest
    
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

%% End the function with NaN output variables if the unit doesnt exist
if isempty(N)
    fprintf('%s does not exist \n', unit_name);
    bs_fr = NaN;
    std_bs = NaN;
    all_trials_bs_fr = NaN;
    return
end

%% Basic settings, some variable extractions, & definitions

% Extract all the spikes of the unit
spikes = xds.spikes{1, N};

% Define period before gocue & end to measure
time_before_gocue = 0.4;

% Extract the target directions & centers
[target_dirs, target_centers] = Identify_Targets(xds);

% Do you want a baseline firing rate for each target / direction combo? (1 = Yes, 0 = No)
per_dir_bsfr = 0;

%% Indexes for rewarded trials in all directions
% Counts the number of directions used
num_dirs = length(target_dirs);

%% Begin the loop through all directions
for jj = 1:num_dirs
    
    %% Times for rewarded trials
    if ~isequal(per_dir_bsfr, 0)
        [rewarded_gocue_time] = EventAlignmentTimes(xds, target_dirs(jj), target_centers(jj), 'trial_gocue');
    else
        [rewarded_gocue_time] = EventAlignmentTimes(xds, NaN, NaN, 'trial_gocue');
    end
    
    %% Define the output variables
    if jj == 1 && ~isequal(per_dir_bsfr, 0)
        bs_fr = zeros(num_dirs, 1);
        all_trials_bs_fr = struct([]);
        std_bs = zeros(num_dirs, 1);
    elseif jj == 1 && ~isequal(per_dir_bsfr, 1)
        bs_fr = zeros(1, 1);
        all_trials_bs_fr = struct([]);
        std_bs = zeros(1, 1);
    end 

    %% Baseline Firing Rate
    for ii = 1:length(rewarded_gocue_time)
        t_start = rewarded_gocue_time(ii) - time_before_gocue;
        t_end = rewarded_gocue_time(ii);
        all_trials_bs_fr{jj,1}(ii,1) = length(find((spikes >= t_start) & ...
                (spikes <= t_end))) / (time_before_gocue);
    end
        
    %% Defining the output variables

    % Baseline firing rate
    bs_fr(jj,1) = mean(all_trials_bs_fr{jj,1});
    % Standard Deviation
    std_bs(jj,1) = std(all_trials_bs_fr{jj,1});

    % End the function after one loop if using all targets
    if isequal(per_dir_bsfr, 0)
        return
    end
    
end % End of target loop



