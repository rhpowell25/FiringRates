
function max_YLim = YLimit(xds_morn, xds_noon, event, unit_name)

%% Display the functions being used
disp('Y-Limit Function:');

%% Extract the target directions & centers
[target_dirs_morn, target_centers_morn] = Identify_Targets(xds_morn);
[target_dirs_noon, target_centers_noon] = Identify_Targets(xds_noon);

%% Begin the loop through all directions
avg_hists_spikes_morn = struct([]);
for jj = 1:length(target_dirs_morn)
    [avg_hists_spikes_morn{jj}, ~, ~] = ...
        EventWindow(xds_morn, unit_name, target_dirs_morn(jj), target_centers_morn(jj), event);
end

avg_hists_spikes_noon = struct([]);
for jj = 1:length(target_dirs_noon)
    [avg_hists_spikes_noon{jj}, ~, ~] = ...
        EventWindow(xds_noon, unit_name, target_dirs_noon(jj), target_centers_noon(jj), event);
end

%% Finding the maximum of spikes
max_morn_fr = zeros(length(avg_hists_spikes_morn),1);
max_noon_fr = zeros(length(avg_hists_spikes_noon),1);

for ii = 1:length(avg_hists_spikes_morn)
    max_morn_fr(ii) = max(avg_hists_spikes_morn{ii});
end

for ii = 1:length(avg_hists_spikes_noon)
    max_noon_fr(ii) = max(avg_hists_spikes_noon{ii});
end

%% Concatenate the morning and afternoon maximums
max_fr = cat(1, max_morn_fr, max_noon_fr);

%% Find the maximum of all the firing rates
max_YLim = max(max_fr);
% Round up to the nearest fifth digit
max_YLim = (round(max_YLim / 5)) * 5 + 15;


