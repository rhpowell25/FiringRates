function Spike_Trigger_Avg(xds, unit_name, Plot_Figs, Save_Figs)

%% Display the function being used
disp('Spike Trigger Average Function:');

%% Load the excel file
if ~ischar(unit_name)

    [xds_output] = Find_Excel(xds);

    %% Find the unit of interest

    unit = xds_output.unit_names(unit_name);

    %% Identify the index of the unit
    N = find(strcmp(xds.unit_names, unit));

else
    N = find(strcmp(xds.unit_names, unit_name));
end

%% If The Unit Doesn't Exist

if isempty(N)
    fprintf('%s does not exist \n', unit_name);
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

% Find the EMG index
if contains(xds.meta.rawFileName, 'PG')
    muscle_groups = 'Grasp';
    [M] = EMG_Index(xds, muscle_groups);
    EMG_Names = string;
    for ii = 1:length(M)
        EMG_Names(ii,1) = strrep(string(xds.EMG_names(M(ii))),'EMG_','');
    end
end

% Font & figure specifications
label_font_size = 15;
legend_font_size = 12;
title_font_size = 15;
font_name = 'Arial';
figure_width = 750;
figure_height = 250;

% Close all previously open figures if you're saving 
if ~isequal(Save_Figs, 0)
    close all
end

% Extract the target directions & centers
[target_dirs, ~] = Identify_Targets(xds);

%% Indexes for rewarded trials in all directions
% Counts the number of directions used
num_dir = length(unique(target_dirs));

%% Begin the loop through all directions
for jj = 1:num_dir

    %% Find the EMG index
    if isequal(xds.meta.task, 'WS')
        if isequal(target_dir(jj), 0) && strcmp(xds.meta.hand, 'Left')
            muscle_groups = 'Flex';
            [M] = EMG_Index(xds, muscle_groups);
        end
        if isequal(target_dir(jj), 90)
            muscle_groups = 'Rad_Dev';
            [M] = EMG_Index(xds, muscle_groups);
        end
        if isequal(target_dir(jj), 180) && strcmp(xds.meta.hand, 'Left')
            muscle_groups = 'Exten';
            [M] = EMG_Index(xds, muscle_groups);
        end
        if isequal(target_dir(jj), -90)
            muscle_groups = 'Uln_Dev';
            [M] = EMG_Index(xds, muscle_groups);
        end
    end

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

    %% Collecting the rectified raw EMG around each spike event
    all_trials_raw_EMG = struct([]);
    for ii = 1:length(total_spike_idx)
        for mm = 1:length(M)
            all_trials_raw_EMG{1,mm}(:,ii) = abs(xds.raw_EMG(total_spike_idx(ii) - pre_spike_idx : ...
                total_spike_idx(ii) + post_spike_idx, M(mm)));
        end
    end

    %% Calculating average EMG
    avg_raw_EMG = struct([]);
    for ii = 1:length(M)
        avg_raw_EMG{ii,1} = zeros(height(all_trials_raw_EMG{1,1}),1);
        for mm = 1:length(avg_raw_EMG{1,1})
            avg_raw_EMG{ii,1}(mm,1) = mean(all_trials_raw_EMG{ii}(mm,:));
        end
    end
    
    %% Plot the EMG
    if isequal(Plot_Figs, 1)

        for mm = 1:length(M)

            raw_EMG_figure = figure;
            raw_EMG_figure.Position = [300 300 figure_width figure_height];
            hold on

            plot(absolute_EMG_timing, avg_raw_EMG{mm,1}, ...
                'LineWidth', 2);

            % Titling the plot
            title(sprintf('%s Spike-Trig Avg, %i°', ...
                char(xds.unit_names(N)), target_dirs(jj)), 'FontSize', title_font_size)

            % Set the labels
            ylabel('Rectified Raw EMG', 'FontSize', label_font_size);
            xlabel('Time (sec.)', 'FontSize', label_font_size);

            % Remove the box of the plot
            box off

            %% Set the legend
            
            legend(sprintf('%s', EMG_Names(mm,1)), ... 
                'NumColumns', 1, 'FontSize', legend_font_size, 'FontName', font_name, ...
                'Location', 'NorthEast');
            
            % Remove the box of the plot
            legend boxoff

        end % End of the EMG loop

    end % End of the Plot_Figs loop

end % End of target loop

%% Define the save directory & save the figures
if ~isequal(Save_Figs, 0)
    save_dir = 'C:\Users\rhpow\Desktop\';
    for ii = 1:numel(findobj('type','figure'))
        fig_info = get(gca,'title');
        save_title = get(fig_info, 'string');
        save_title = strrep(save_title, ':', '');
        save_title = strrep(save_title, 'vs.', 'vs');
        save_title = strrep(save_title, 'mg.', 'mg');
        save_title = strrep(save_title, 'kg.', 'kg');
        save_title = strrep(save_title, '.', '_');
        save_title = strrep(save_title, '/', '_');
        if ~strcmp(Save_Figs, 'All')
            saveas(gcf, fullfile(save_dir, char(save_title)), Save_Figs)
        end
        if strcmp(Save_Figs, 'All')
            saveas(gcf, fullfile(save_dir, char(save_title)), 'png')
            saveas(gcf, fullfile(save_dir, char(save_title)), 'pdf')
            saveas(gcf, fullfile(save_dir, char(save_title)), 'fig')
        end
        close gcf
    end
end
