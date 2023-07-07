function [Alignment_Times] = CursorOnsetAlignmentTimes(xds, target_dir, target_center)

%% Catch possible sources of error

% If there is no cursor information
if ~isfield(xds, 'curs_p')
    disp('No cursor information in this file');
    Alignment_Times = NaN;
    return
end

%% Basic settings, some variable extractions, & definitions

% Window to calculate the cursor onset
half_window_size = 1; % Bins
step_size = 1; % Bins

%% Times for rewarded trials

[rewarded_gocue_time] = GoCueAlignmentTimes(xds, target_dir, target_center);
[rewarded_end_time] = TrialEndAlignmentTimes(xds, target_dir, target_center);

%% Extracting cursor position & time during successful trials

% Cursor position & time measured during each successful trial 
cursor_p = struct([]); % Cursor position during each successful trial 
timings = struct([]); % Time points during each succesful trial 
for ii = 1:length(rewarded_gocue_time)
    idx = find((xds.time_frame > rewarded_gocue_time(ii)) & ...
        (xds.time_frame < rewarded_end_time(ii))); 
    cursor_p{ii, 1} = xds.curs_p(idx, :);
    timings{ii, 1} = xds.time_frame(idx);
end

%% Find the vector sum of the cursor position

z_cursor_p = struct([]);
for ii = 1:length(rewarded_gocue_time)
    z_cursor_p{ii,1} = zeros(length(cursor_p{ii,1}(:,1)),1);
    for dd = 1:length(z_cursor_p{ii,1})
        z_cursor_p{ii,1}(dd,1) = sqrt(cursor_p{ii,1}(dd,1).^2 + cursor_p{ii,1}(dd,2).^2);
    end
end

%% Defines onset time via the maximum cursor positon

cursor_onset_idx = zeros(length(rewarded_gocue_time),1);
% Loop through cursor position
for ii = 1:length(rewarded_gocue_time)
    [sliding_avg, ~, ~] = Sliding_Window(z_cursor_p{ii,1}, half_window_size, step_size);
    % Find the peak cursor position
    temp_1 = find(sliding_avg == max(sliding_avg));
    % Find the onset of this peak
    temp_2 = find(z_cursor_p{ii,1}(1:temp_1) < prctile(z_cursor_p{ii,1}, 15));
    if isempty(temp_2)
        temp_2 = find(z_cursor_p{ii,1}(1:temp_1) == min(z_cursor_p{ii,1}(1:temp_1)));
    end
    cursor_onset_idx(ii,1) = temp_2(end);
end

%% Convert the onset_time_idx array into actual timings in seconds

Alignment_Times = zeros(length(timings),1);
for ii = 1:length(timings)
    Alignment_Times(ii) = timings{ii, 1}(cursor_onset_idx(ii));
end





