function [EMG_Names, peak_to_noise_ratio] = Spike_Trigger_Avg(xds, unit_name, pref_dir, Plot_Figs, Save_File)

%% Display the function being used
disp('Spike Trigger Average Function:');

%% Find the unit of interest
[N] = Find_Unit(xds, unit_name);

%% Catch possible sources of error
% If there is no unit of that name
if isempty(N)
    fprintf('%s does not exist \n', unit_name);
    EMG_Names = NaN;
    peak_to_noise_ratio = NaN;
    return
end

% If there is no EMG
if ~xds.has_EMG
    disp('No EMG in this file');
    EMG_Names = NaN;
    peak_to_noise_ratio = NaN;
    return
end

%% Basic Settings, some variable extractions, & definitions

bin_width = xds.bin_width;

% 5 ms before each spike
pre_spike_time = 0.005;
pre_spike_idx = pre_spike_time / (bin_width/2);
% 25 ms after each spike
post_spike_time = 0.025;
post_spike_idx = post_spike_time / (bin_width/2);

% Length of the measured period
absolute_EMG_timing = linspace(-pre_spike_time, post_spike_time, (pre_spike_idx + post_spike_idx + 1));

% Font & plotting specifications
[Plot_Params] = Plot_Parameters;

% Close all previously open figures if you're saving 
if ~isequal(Save_File, 0)
    close all
end

%% Define the EMG of interest, based on the task & the unit's preferred direction

[muscle_groups] = Hand_Muscle_Match(xds, pref_dir);
[M] = EMG_Index(xds, muscle_groups);

% Find the EMG index
EMG_Names = string;
for ii = 1:length(M)
    EMG_Names(ii,1) = strrep(string(xds.EMG_names(M(ii))),'EMG_','');
end

%% Times for rewarded trials
[rewarded_gocue_time] = EventAlignmentTimes(xds, NaN, NaN, 'trial_gocue');
[rewarded_end_time] = EventAlignmentTimes(xds, NaN, NaN, 'trial_end');

%% Spikes during the succesful trial
spikes = xds.spikes{1, N};

aligned_spikes = struct([]); % Spikes during each successful trial
round_aligned_spikes = struct([]);
for ii = 1:length(rewarded_gocue_time)
    aligned_spikes{ii, 1} = spikes((spikes >= rewarded_gocue_time(ii)) & (spikes <= rewarded_end_time(ii)));
    round_aligned_spikes{ii, 1} = round(2000*aligned_spikes{ii, 1})/2000;
end

%% Index of each spike in the raw EMG time frame
round_raw_EMG_time_frame = round(2000*xds.raw_EMG_time_frame)/2000;
aligned_spike_idx = struct([]);
for ii = 1:length(rewarded_gocue_time)
    for tt = 1:length(round_aligned_spikes{ii, 1})
        spike_idx = find(round_raw_EMG_time_frame == round_aligned_spikes{ii, 1}(tt,1));
        aligned_spike_idx{ii, 1}(tt,1) = spike_idx(1);
    end
end

%% Put all the spike indexes into one array
% Find the total amount of spike events
spikes_per_trial = zeros(length(aligned_spike_idx),1);
for ii = 1:length(spikes_per_trial)
    spikes_per_trial(ii) = length(aligned_spike_idx{ii,1});
end
total_spikes = sum(spikes_per_trial);

% Concatenate all the information
total_spike_idx = zeros(length(total_spikes),1);
cc = 1;
for ii = 1:length(aligned_spike_idx)
    for tt = 1:length(aligned_spike_idx{ii})
        total_spike_idx(cc,1) = aligned_spike_idx{ii,1}(tt,1);
        cc = cc + 1;
    end
end

%% Begin the loop through all EMG channels
for mm = 1:length(M)

    %% Define the output variables
    if mm == 1
        EMG_Names = strings;
        peak_to_noise_ratio = zeros(length(M),1);
    end

    %% Find the EMG name

    EMG_Names(mm) = strrep(string(xds.EMG_names(M(mm))),'EMG_','');

    %% Collecting the rectified raw EMG around each spike event
    all_trials_rect_EMG = zeros(pre_spike_idx + post_spike_idx + 1, length(total_spike_idx));
    for ii = 1:length(total_spike_idx)
        all_trials_rect_EMG(:,ii) = abs(xds.raw_EMG(total_spike_idx(ii) - pre_spike_idx : ...
            total_spike_idx(ii) + post_spike_idx, M(mm)));
    end

    %% Calculating average rectified EMG
    avg_rect_EMG = zeros(pre_spike_idx + post_spike_idx + 1, 1);
    for ii = 1:length(avg_rect_EMG)
        avg_rect_EMG(ii,1) = mean(all_trials_rect_EMG(ii,:));
    end

    %% Calculate the baseline EMG noise
    baseline_EMG_noise = maxk(avg_rect_EMG(1:pre_spike_idx), 3);
    avg_baseline_EMG_noise = mean(baseline_EMG_noise);

    baseline_noise_idx = zeros(3,1);
    for ii = 1:length(baseline_noise_idx)
        baseline_noise_idx(ii) = find(avg_rect_EMG(1:pre_spike_idx) == baseline_EMG_noise(ii), 1, 'first');
    end

    %% Calculate the peak-to-noise ratio
    peak_facil = max(avg_rect_EMG(pre_spike_idx + 1:end));
    peak_facil_idx = find(avg_rect_EMG(pre_spike_idx + 1:end) == peak_facil) + pre_spike_idx;
    peak_to_noise_ratio(mm,1) = max(avg_rect_EMG(pre_spike_idx + 1:end)) / avg_baseline_EMG_noise;
    
    %% Plot the EMG
    if isequal(Plot_Figs, 1)

        raw_EMG_figure = figure;
        raw_EMG_figure.Position = [300 300 Plot_Params.fig_size Plot_Params.fig_size / 2];
        hold on

        plot(absolute_EMG_timing, avg_rect_EMG, 'k', 'LineWidth', 2);

        % Titling the plot
        Fig_Title = strcat(char(xds.unit_names(N)), {' '}, 'Spike-Trig Avg,', {' '},  pref_dir);
        title(Fig_Title, 'FontSize', Plot_Params.title_font_size)

        % Set the labels
        ylabel('Rectified EMG', 'FontSize', Plot_Params.label_font_size);
        xlabel('Time (sec.)', 'FontSize', Plot_Params.label_font_size);

        % Plot the baseline noise as dark green dots
        for ii = 1:length(baseline_noise_idx)
            plot(absolute_EMG_timing(baseline_noise_idx(ii)), baseline_EMG_noise(ii), ...
                'Marker', '.', 'Color', [0 0.5 0], 'Markersize', 20);
        end
        % Plot the peak facilitation as a red dot
        plot(absolute_EMG_timing(peak_facil_idx), peak_facil, ...
            'Marker', '.', 'Color', 'r', 'Markersize', 20);

        % Remove the box of the plot
        box off

        % Annotate the peak to noise ratio
        legend_dims = [0.025 0.4 0.44 0.44];
        perc_change_string = strcat('PSNR =', {' '}, mat2str(round(peak_to_noise_ratio(mm,1), 2)));
        legend_string = {char(perc_change_string)};
        ann_legend = annotation('textbox', legend_dims, 'String', legend_string, ... 
            'FitBoxToText', 'on', 'verticalalignment', 'top', ... 
            'EdgeColor','none', 'horizontalalignment', 'center');
        ann_legend.FontSize = Plot_Params.legend_size;
        ann_legend.FontName = Plot_Params.font_name;

        % Set the legend
        legend(sprintf('%s', EMG_Names(mm)), ... 
            'NumColumns', 1, 'FontSize', Plot_Params.legend_size, 'FontName', Plot_Params.font_name, ...
            'Location', 'NorthEast');
        
        % Remove the box of the legend
        legend boxoff

        %% Save the file if selected
        Save_File(Fig_Title, Save_File)

    end % End of the Plot_Figs loop

end % End of EMG loop

