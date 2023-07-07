function [Alignment_Times] = ForceOnsetAlignmentTimes(xds, target_dir, target_center)

%% Basic settings, some variable extractions, & definitions

% Window to calculate max firing rate
half_window_size = 1; % Bins
step_size = 1; % Bins

%% Times for rewarded trials

[rewarded_gocue_time] = GoCueAlignmentTimes(xds, target_dir, target_center);
[rewarded_end_time] = TrialEndAlignmentTimes(xds, target_dir, target_center);

%% Extracting force & time during successful trials

% Force & time measured during each successful trial 
Force = struct([]); % Force during each successful trial 
timings = struct([]); % Time points during each succesful trial 
for ii = 1:length(rewarded_gocue_time)
    idx = find(xds.time_frame > rewarded_gocue_time(ii) & ...
        xds.time_frame < rewarded_end_time(ii)); 
    Force{ii, 1} = xds.force(idx, :);
    timings{ii, 1} = xds.time_frame(idx);
end

%% Sum the two force transducers
[Sigma_Force] = Sum_Force(xds.meta.task, Force);

%% Defines onset time via the force onset

force_onset_idx = zeros(length(rewarded_gocue_time),1);
% Loop through force
for ii = 1:length(rewarded_gocue_time)
    [sliding_avg, ~, ~] = Sliding_Window(Sigma_Force{ii,1}, half_window_size, step_size);
    % Find the peak force
    temp_1 = find(sliding_avg == max(sliding_avg));
    % Find the onset of this peak
    try
        temp_2 = find(Sigma_Force{ii,1}(1:temp_1) < prctile(Sigma_Force{ii,1}, 15));
        force_onset_idx(ii,1) = temp_2(end);
    catch
        temp_2 = find(Sigma_Force{ii,1}(1:temp_1) == min(Sigma_Force{ii,1}(1:temp_1)));
        force_onset_idx(ii,1) = temp_2;
    end
end

%% Convert the onset_time_idx array into actual timings in seconds

Alignment_Times = zeros(length(timings),1);
for ii = 1:length(timings)
    Alignment_Times(ii) = timings{ii, 1}(force_onset_idx(ii));
end







