function [mp_fr, std_mp, pertrial_mpfr] = ...
    EventPeakFiringRate(xds, unit_name, event)

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
    mp_fr = NaN;
    std_mp = NaN;
    pertrial_mpfr = NaN;
    return
end

%% Basic settings, some variable extractions, & definitions

% Extract all the spikes of the unit
spikes = xds.spikes{1, N};

% Window to calculate max firing rate
window_size = 0.1;

% Extract the target directions & centers
[target_dirs, target_centers] = Identify_Targets(xds);

%% Indexes for rewarded trials in all directions
% Counts the number of directions used
num_dir = length(target_dirs);

%% Begin the loop through all directions
for jj = 1:num_dir
    
    %% Times for rewarded trials
    [Alignment_Times] = EventAlignmentTimes(xds, target_dirs(jj), target_centers(jj), event);

    %% Time period for peak firing rate
    if contains(event, 'window')
        [~, max_fr_time, ~] = EventWindow(xds, unit_name, target_dirs(jj), target_centers(jj), event);
    else
        max_fr_time = 0;
    end

    %% Define the output variables
    if jj == 1
        mp_fr = zeros(num_dir, 1);
        std_mp = zeros(num_dir, 1);
        pertrial_mpfr = struct([]);
    end

    %% Peak firing rate
    for ii = 1:length(Alignment_Times)
        t_start = Alignment_Times(ii) + max_fr_time - window_size;
        t_end = Alignment_Times(ii) + max_fr_time + window_size;
        pertrial_mpfr{jj,1}(ii,1) = length(find((spikes >= t_start) & ...
                (spikes <= t_end))) / (2*window_size);
    end

    %% Defining the output variables

    % Peak firing rate
    mp_fr(jj,1) = mean(pertrial_mpfr{jj,1});
    % Standard Deviation
    std_mp(jj,1) = std(pertrial_mpfr{jj,1});
    
end % End of target loop



