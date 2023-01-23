function [Alignment_Times] = ForceDerivAlignmentTimes(xds, target_dir, target_center)

%% Times for rewarded trials

[rewarded_gocue_time] = GoCueAlignmentTimes(xds, target_dir, target_center);
[rewarded_end_time] = TrialEndAlignmentTimes(xds, target_dir, target_center);

%% Extracting force & time during successful trials

% Force & time measured during each successful trial 
force = struct([]); % Force during each successful trial 
timings = struct([]); % Time points during each succesful trial 
for ii = 1:length(rewarded_gocue_time)
    idx = find((xds.time_frame > rewarded_gocue_time(ii)) & ...
        (xds.time_frame < rewarded_end_time(ii))); 
    force{ii, 1} = xds.force(idx, :);
    timings{ii, 1} = xds.time_frame(idx);
end

%% Sum the two force transducers

z_force = struct([]);
for ii = 1:length(rewarded_gocue_time)
    z_force{ii,1} = force{ii,1}(:,1) + force{ii,1}(:,2);
end

%% Defines onset time via the force onset

force_onset_idx = zeros(length(rewarded_gocue_time),1);
% Loop through force
for ii = 1:length(rewarded_gocue_time)
    % Take the derivative
    d_force = diff(z_force{ii,1});
    % Find the maximum
    max_d = max(d_force);
    temp = find(d_force == max_d);
    force_onset_idx(ii) = temp(1);
end

%% Convert the mpfr_idx array into actual timings in seconds

Alignment_Times = zeros(length(timings),1);
for ii = 1:length(timings)
    Alignment_Times(ii) = timings{ii, 1}(force_onset_idx(ii));
end





