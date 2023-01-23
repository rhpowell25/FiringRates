function Optimal_Alignment(xds, unit_name)

%% Build the array as long as each event
events = strings;
events(1) = 'window_trial_gocue';
events(2) = 'window_trial_end';
if strcmp(xds.meta.task, 'WS')
    events(3) = 'window_cursor_onset';
    events(4) = 'window_cursor_veloc';
    events(5) = 'window_cursor_acc';
elseif strcmp(xds.meta.task, 'multi_gadget')
    events(3) = 'window_force_onset';
    events(4) = 'window_force_deriv';
    events(5) = 'window_force_max';
end

event_depth_mod = zeros(length(events), 1);

% Which targets do you want the mnovement phase firing rate calculated from? ('Max', 'Min', 'All')
tgt_mpfr = 'Max';

%% Get the baseline firing rates
[~, ~, bs_fr, ~, ~, ~] = ... 
    BaselineFiringRate(xds, unit_name);

%% Run the function for each event

for ii = 1:length(events)

    % Get the movement phase firing rates
    [target_dirs, target_centers, mp_fr, ~, ~, ~] = ...
        EventFiringRate(xds, unit_name, events(ii), tgt_mpfr);

    % Calculate the depth of modulation per trial
    perdir_depth = zeros(length(mp_fr), 1);
    for jj = 1:length(mp_fr)
        perdir_depth(jj,1) = mp_fr(jj) - bs_fr;
    end

    % Only look at the preferred direction
    [pref_dir] = EventPreferredDirection(xds, unit_name, events(ii), tgt_mpfr);

    pref_dir_max_tgt = max(target_centers(target_dirs == pref_dir));
    pref_dir_min_tgt = min(target_centers(target_dirs == pref_dir));
        
    % Look at the maximum or minimum targets if not using all targets
    if strcmp(tgt_mpfr, 'Max')
        event_depth_mod(ii) = perdir_depth(target_centers == pref_dir_max_tgt);
    end

    if strcmp(tgt_mpfr, 'Min')
        event_depth_mod(ii) = perdir_depth(target_centers == pref_dir_min_tgt);
    end

end

%% Find the optimal alignment
optimal_alignment = events(event_depth_mod == max(event_depth_mod));

fprintf('The Optimal Alignment is %s\n', char(optimal_alignment));










