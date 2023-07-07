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
events(6) = 'window_EMG_onset';
events(7) = 'window_EMG_max';

event_distribution = zeros(length(events), 1);

% Which targets do you want the mnovement phase firing rate calculated from? ('Max', 'Min', 'All')
tgt_mpfr = 'Max';

% Extract the target directions & centers
[target_dirs, target_centers] = Identify_Targets(xds);

%% Run the function for each event

for ii = 1:length(events)

    % Only look at the preferred direction
    [pref_dir] = EventPreferredDirection(xds, unit_name, events(ii), tgt_mpfr);

    if strcmp(tgt_mpfr, 'Max')
        pref_dir_tgt = max(target_centers(target_dirs == pref_dir));
    elseif strcmp(tgt_mpfr, 'Min')
        pref_dir_tgt = min(target_centers(target_dirs == pref_dir));
    end

    [rewarded_gocue_time] = EventAlignmentTimes(xds, pref_dir, pref_dir_tgt, 'trial_gocue');
    [rewarded_end_time] = EventAlignmentTimes(xds, pref_dir, pref_dir_tgt, 'trial_end');
    [Alignment_Times] = EventAlignmentTimes(xds, pref_dir, pref_dir_tgt, events(ii));

    % Find the trial lengths
    gocue_to_event = Alignment_Times - rewarded_gocue_time;
    event_to_end = rewarded_end_time - Alignment_Times;
        
    % Look at the maximum or minimum targets if not using all targets
    if ~strcmp(events(ii), 'window_trial_end')
        event_distribution(ii) = std(event_to_end);
    else
        event_distribution(ii) = std(gocue_to_event);
    end

end

%% Find the optimal alignment
optimal_alignment = events(event_distribution == min(event_distribution));

for ii = 1:length(optimal_alignment)
    fprintf('The Optimal Alignment is %s\n', char(optimal_alignment(ii)));
end










