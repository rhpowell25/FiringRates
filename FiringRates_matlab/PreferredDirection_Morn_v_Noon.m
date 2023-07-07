function [pref_dir] = PreferredDirection_Morn_v_Noon(xds_morn, xds_noon, unit_name, event, tgt_mpfr)

%% End the function if the task is Powergrasp
if strcmp(xds_morn.meta.task, 'multi_gadget')
    pref_dir = 90;
    return
end

%% Run the baseline and movement phase function
[bs_fr_morn, ~, ~, ~] = BaselineFiringRate(xds_morn, unit_name);
[bs_fr_noon, ~, ~, ~] = BaselineFiringRate(xds_noon, unit_name);

[~, ~, pertrial_mpfr_morn] = EventPeakFiringRate(xds_morn, unit_name, event);
[~, ~, pertrial_mpfr_noon] = EventPeakFiringRate(xds_noon, unit_name, event);

%% Calculate the depth of modulation
depth_mod_morn = struct([]);
for ii = 1:length(pertrial_mpfr_morn)
    depth_mod_morn{ii,1} = pertrial_mpfr_morn{ii,1} - bs_fr_morn;
end
depth_mod_noon = struct([]);
for ii = 1:length(pertrial_mpfr_noon)
    depth_mod_noon{ii,1} = pertrial_mpfr_noon{ii,1} - bs_fr_noon;
end

%% Find the number of target directions
% Extract the target directions & centers
[target_dirs_morn, target_centers_morn] = Identify_Targets(xds_morn);
[target_dirs_noon, target_centers_noon] = Identify_Targets(xds_noon);

%% Check to see if both sessions use a consistent number of targets

% Find matching targets between the two sessions
[Matching_Idxs_Morn, Matching_Idxs_Noon] = ...
    Match_Targets(target_dirs_morn, target_dirs_noon, target_centers_morn, target_centers_noon);

% Only use the info of target centers conserved between morn & noon
if ~all(Matching_Idxs_Morn) || ~all(Matching_Idxs_Noon)
    disp('Uneven Targets Between Morning & Afternoon');
    shared_target_centers = target_centers_morn(Matching_Idxs_Morn);
    shared_target_dirs = target_dirs_morn(Matching_Idxs_Morn);
    depth_mod_morn = depth_mod_morn(Matching_Idxs_Morn);
    depth_mod_noon = depth_mod_noon(Matching_Idxs_Noon);
else
    shared_target_centers = target_centers_morn;
    shared_target_dirs = target_dirs_morn;
end

%% Find the average of the depths of modulation
avg_depth_mod = zeros(length(shared_target_dirs),1);
for ii = 1:length(avg_depth_mod)
    avg_depth_mod(ii,1) = mean(cat(1, depth_mod_morn{ii,1}, depth_mod_noon{ii,1}));
end

%% Find the depth of modulation of the max or min target center in each direction
unique_target_dirs = unique(shared_target_dirs);

tgt_center_depth_mod = zeros(length(unique_target_dirs),1);
for ii = 1:length(unique_target_dirs)
    dir_idx = shared_target_dirs == unique_target_dirs(ii);
    target_centers_idx = shared_target_centers(dir_idx);
    depth_mod_per_dir = avg_depth_mod(dir_idx);
    if strcmp(tgt_mpfr, 'Max')
        max_target_center_idx = target_centers_idx == max(target_centers_idx);
        tgt_center_depth_mod(ii) = depth_mod_per_dir(max_target_center_idx);
    end
    if strcmp(tgt_mpfr, 'Min')
        min_target_center_idx = target_centers_idx == min(target_centers_idx);
        tgt_center_depth_mod(ii) = depth_mod_per_dir(min_target_center_idx);
    end
    if strcmp(tgt_mpfr, 'Mid')
        mid_tgt_cntr = target_centers_idx(ceil(numel(target_centers_idx)/2));
        mid_target_center_idx = target_centers_idx == mid_tgt_cntr;
        tgt_center_depth_mod(ii) = depth_mod_per_dir(mid_target_center_idx);
    end
end

%% Find the preferred direction
max_mod = max(tgt_center_depth_mod);
max_mod_idx = avg_depth_mod == max_mod;

pref_dir = unique(shared_target_dirs(max_mod_idx));
pref_dir = pref_dir(1);

%% Printing the preferred direction

if ischar(unit_name)
    fprintf('%s''s preferred direction is %0.f° \n', unit_name, pref_dir);
else
    fprintf("The unit's preferred direction is %0.f° \n", pref_dir);
end












