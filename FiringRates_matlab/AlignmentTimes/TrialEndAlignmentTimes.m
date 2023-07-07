function [Alignment_Times] = TrialEndAlignmentTimes(xds, target_dir, target_center)

%% Indexes for rewarded trials

[rewarded_idxs] = Rewarded_Indexes(xds, target_dir, target_center);

%% Loops to extract only rewarded trials

% End times for succesful trials
Alignment_Times = zeros(length(rewarded_idxs),1);
for jj = 1:length(rewarded_idxs)
    Alignment_Times(jj) = xds.trial_end_time(rewarded_idxs(jj));
end






