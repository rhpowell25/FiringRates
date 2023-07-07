function [Alignment_Times] = GoCueAlignmentTimes(xds, target_dir, target_center)

%% Indexes for rewarded trials

[rewarded_idxs] = Rewarded_Indexes(xds, target_dir, target_center);

%% Loops to extract only rewarded trials

% Go-cue's for succesful trials
Alignment_Times = zeros(height(rewarded_idxs),1);
for jj = 1:height(rewarded_idxs)
    Alignment_Times(jj) = xds.trial_gocue_time(rewarded_idxs(jj));
end

% Round to match the neural bin size
Alignment_Times = round(Alignment_Times, abs(floor(log10(xds.bin_width))));








