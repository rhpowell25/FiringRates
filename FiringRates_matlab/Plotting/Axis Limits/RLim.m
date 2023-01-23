function max_RLims = RLim(xds_morn, xds_noon, unit_name, event)

%% Display the functions being used
disp('R-Limit Function:');

%% Run the baseline and movement phase firing rate function
[mp_fr_morn, std_mp_morn, ~] = EventPeakFiringRate(xds_morn, unit_name, event);
[mp_fr_noon, std_mp_noon, ~] = EventPeakFiringRate(xds_noon, unit_name, event);

[bs_fr_morn, std_bs_morn, ~] = BaselineFiringRate(xds_morn, unit_name);
[bs_fr_noon, std_bs_noon, ~] = BaselineFiringRate(xds_noon, unit_name);

%% Concatenate all the outputs
fr = cat(1, (bs_fr_morn + std_bs_morn), (bs_fr_noon + std_bs_noon), ... 
    (mp_fr_morn + std_mp_morn), (mp_fr_noon + std_mp_noon));

%% Find the maximum of all the firing rates
max_RLims = max(fr);
% Round up to the nearest fifth digit
max_RLims = (round(max_RLims / 5)) * 5 + 5;
