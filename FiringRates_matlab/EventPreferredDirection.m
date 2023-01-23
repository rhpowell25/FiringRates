function [pref_dir] = EventPreferredDirection(xds, unit_name, event, tgt_mpfr)

%% End the function if the task is Powergrasp
if strcmp(xds.meta.task, 'multi_gadget')
    pref_dir = 90;
    return
end

%% Run the baseline and movement phase function (Aligned to trial end)
[bs_fr, ~, ~] = BaselineFiringRate(xds, unit_name);

[mp_fr, ~, ~] = EventPeakFiringRate(xds, unit_name, event);

%% Calculate the depth of modulation

depth_mod = mp_fr - bs_fr;

%% Find the number of target directions
% Extract the target directions & centers
[target_dirs, target_centers] = Identify_Targets(xds);
unique_target_dirs = unique(target_dirs);

%% Put all trials & target information into a single array

%for ii = 1:length(all_trials_max_fr)
%    if ii == 1
%        all_trials_target_dirs = zeros(length(all_trials_max_fr{ii}),1) + target_dirs(ii);
%        all_trials_target_centers = zeros(length(all_trials_max_fr{ii}),1) + target_centers(ii);
%        all_trials_depth_mod = all_trials_max_fr{ii} - bs_fr;
%    else
%        all_trials_target_dirs = cat(1, all_trials_target_dirs, zeros(length(all_trials_max_fr{ii}),1) + target_dirs(ii));
%        all_trials_target_centers = cat(1, all_trials_target_centers, zeros(length(all_trials_max_fr{ii}),1) + target_centers(ii));
%        all_trials_depth_mod = cat(1, all_trials_depth_mod, all_trials_max_fr{ii} - bs_fr);
%    end
%end

%% Find the depth of modulation of the max or min target center in each direction

tgt_center_depth_mod = zeros(length(unique_target_dirs),1);
for ii = 1:length(unique_target_dirs)
    dir_idx = target_dirs == unique_target_dirs(ii);
    target_centers_idx = target_centers(dir_idx);
    depth_mod_per_dir = depth_mod(dir_idx);
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
max_mod_idx = depth_mod == max_mod;

pref_dir = unique(target_dirs(max_mod_idx));
pref_dir = pref_dir(1);

%% Printing the preferred direction

if ischar(unit_name)
    fprintf('%s''s preferred direction is %0.f° \n', unit_name, pref_dir);
else
    fprintf("The unit's preferred direction is %0.f° \n", pref_dir);
end












