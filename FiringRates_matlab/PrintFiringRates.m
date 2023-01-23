function PrintFiringRates(xds_morn, xds_noon, unit_name, event)

%% Display the function being used
disp('Print Firing Rates Function:');

%% Load the excel file
if ~ischar(unit_name)

    [xds_output] = Find_Excel(xds_morn);

    %% Find the unit of interest

    unit = xds_output.unit_names(unit_name);

else
    unit = unit_name;
end

%% Run the function according to the event

if strcmp(event, 'trial_gocue')
    disp('Baseline Firing Rate:');
    [bs_fr_morn, ~, ~] = ...
        BaselineFiringRate(xds_morn, unit_name);
    [bs_fr_noon, ~, ~] = ... 
        BaselineFiringRate(xds_noon, unit_name);
else
    [mp_fr_morn, ~, ~] = EventPeakFiringRate(xds_morn, unit_name, event);
    [mp_fr_noon, ~, ~] = EventPeakFiringRate(xds_noon, unit_name, event);
end

% Extract the target directions & centers
[target_dirs_morn, target_centers_morn] = Identify_Targets(xds_morn);
[target_dirs_noon, target_centers_noon] = Identify_Targets(xds_noon);

%% Check to see if both sessions use a consistent number of directions

if ~strcmp(event, 'trial_gocue')
    % Find matching targets between the two sessions
    [Matching_Idxs_Morn, Matching_Idxs_Noon] = ...
        Match_Targets(target_dirs_morn, target_dirs_noon, target_centers_morn, target_centers_noon);
    
    if ~all(Matching_Idxs_Morn) || ~all(Matching_Idxs_Noon)
        disp('Uneven Targets Between Morning & Afternoon');
        % Only print the info of target centers conserved between morn & noon
        target_centers_morn = target_centers_morn(Matching_Idxs_Morn);
        mp_fr_morn = mp_fr_morn(Matching_Idxs_Morn);
        mp_fr_noon = mp_fr_noon(Matching_Idxs_Noon);
        target_dirs_morn = target_dirs_morn(Matching_Idxs_Morn);
    end
end

%% Begin the loop through all directions
for jj = 1:length(target_dirs_morn)
    
    %% Printing the selected directions

    % Print the target center & direction
    if ~ischar(target_centers_morn)
        fprintf("Target direction: %0.f°, target center: %0.f \n", ... 
            target_dirs_morn(jj,1), target_centers_morn(jj,1));
    end

    if strcmp(event, 'trial_gocue')
        % Print the baseline firing rate in the morning
        fprintf("The mean baseline firing rate of %s is %0.1f Hz in the morning \n", ...
            string(unit), bs_fr_morn(jj,1));
        % Print the baseline firing rate in the afternoon
        fprintf("The mean baseline firing rate of %s is %0.1f Hz in the afternoon \n", ...
            string(unit), bs_fr_noon(jj,1));
        return
    else
        % Print the peak firing rate in the morning
        fprintf("The mean movement phase firing rate of %s is %0.1f Hz in the morning \n", ...
            string(unit), mp_fr_morn(jj,1));
        % Print the peak firing rate in the afternoon
        fprintf("The mean movement phase firing rate of %s is %0.1f Hz in the afternoon \n", ...
            string(unit), mp_fr_noon(jj,1));
    end

end % End of target direction loop

