function [Alignment_Times] = TrialStartAlignmentTimes(xds, target_dir, target_center)

%% Indexes for rewarded trials

tgt_Center_header = contains(xds.trial_info_table_header, 'TgtDistance');
tgt_Center_idx = cell2mat(xds.trial_info_table(:, tgt_Center_header));

if isnan(target_dir) || isnan(target_center)
    rewarded_idx = find(xds.trial_result == 'R');
else
    rewarded_idx = find((xds.trial_result == 'R') & (xds.trial_target_dir == target_dir) & ...
        (tgt_Center_idx == target_center));
end

%% Loops to extract only rewarded trials

% Go-cue's for succesful trials
Alignment_Times = zeros(height(rewarded_idx),1);
for ii = 1:height(rewarded_idx)
    Alignment_Times(ii) = xds.trial_start_time(rewarded_idx(ii));
end

% Round to match the neural bin size
Alignment_Times = round(Alignment_Times, abs(floor(log10(xds.bin_width))));







