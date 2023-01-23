function [Alignment_Times] = CursorVelocAlignmentTimes(xds, target_dir, target_center)

%% Times for rewarded trials

[rewarded_gocue_time] = GoCueAlignmentTimes(xds, target_dir, target_center);
[rewarded_end_time] = TrialEndAlignmentTimes(xds, target_dir, target_center);

%% Extracting cursor velocity and time during successful trials

% Cursor velocity & time measured during each successful trial 
cursor_v = struct([]); % Cursor velocity during each successful trial 
timings = struct([]); % Time points during each succesful trial 
for ii = 1:length(rewarded_gocue_time)
    idx = find((xds.time_frame > rewarded_gocue_time(ii)) & ...
        (xds.time_frame < rewarded_end_time(ii))); 
    cursor_v{ii, 1} = xds.curs_v(idx, :);
    timings{ii, 1} = xds.time_frame(idx);
end

%% Find the vector sum of the cursor velocity

z_cursor_v = struct([]);
for ii = 1:length(rewarded_gocue_time)
    z_cursor_v{ii,1} = zeros(length(cursor_v{ii,1}(:,1)),1);
    for dd = 1:length(z_cursor_v{ii,1})
        z_cursor_v{ii,1}(dd,1) = sqrt(cursor_v{ii,1}(dd,1).^2 + cursor_v{ii,1}(dd,2).^2);
    end
end

%% Defines onset time via the peak cursor velocity

peak_cursor_velocity_idx = zeros(length(rewarded_gocue_time),1);
% Loops through cursor velocity
for ii = 1:length(rewarded_gocue_time)
    % Finds the maximum
    max_z = max(z_cursor_v{ii,1});
    temp = find(z_cursor_v{ii,1} == max_z);
    peak_cursor_velocity_idx(ii) = temp(1); 
end

%% Convert the onset_time_idx array into actual timings in seconds

Alignment_Times = zeros(length(timings),1);
for ii = 1:length(timings)
    Alignment_Times(ii) = timings{ii, 1}(peak_cursor_velocity_idx(ii));
end





