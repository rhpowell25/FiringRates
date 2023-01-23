
function [Alignment_Times] = TrialEndAlignmentTimes(xds, target_dir, target_center)

%% Indexes for rewarded trials

tgt_Center_header = contains(xds.trial_info_table_header, 'TgtDistance');
tgt_Center_idx = cell2mat(xds.trial_info_table(:, tgt_Center_header));

if isnan(target_dir) && isnan(target_center)
    rewarded_idx = find(xds.trial_result == 'R');
elseif isnan(target_dir) && stcmp(target_center, 'Max')
    rewarded_idx = Find_Max_Indexes(xds);
else
    rewarded_idx = find((xds.trial_result == 'R') & (xds.trial_target_dir == target_dir) & ...
        (tgt_Center_idx == target_center));
end

%% Loops to extract only rewarded trials

% End times for succesful trials
Alignment_Times = zeros(length(rewarded_idx),1);
for ii = 1:length(rewarded_idx)
    Alignment_Times(ii) = xds.trial_end_time(rewarded_idx(ii));
end





