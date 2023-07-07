function ConsecRasterPlot(xds, unit_name, target_dirs, trial_num, heat_map)

%% Display the function being used
clc
disp('Consecutive Raster Plot Function:');

%% Find the unit of interest
[N] = Find_Unit(xds, unit_name);

%% Some variable extraction & definitions

% Pull the binning paramaters
[Bin_Params] = Binning_Parameters;

% Binning information
bin_size = Bin_Params.bin_size; % Time (sec.)

% Font specifications
label_font_size = 17;
legend_font_size = 13;
title_font_size = 14;
font_name = 'Arial';

% Define the window for the baseline phase
time_before_gocue = 0.4;

% Do you want to plot the trial lines (Yes = 1; No = 0)
trial_lines = 0;

%% Indexes for rewarded trials

% If a single direction was selected
if ~strcmp(target_dirs, 'All') || ~strcmp(trial_num, 'All')
    
    if ~strcmp(target_dirs, 'All')
        rewarded_trial_idx = find((xds.trial_result == 'R') & (round(xds.trial_target_dir) == target_dirs));
    else
        rewarded_trial_idx = find(xds.trial_result == 'R');
    end

    %% Index for rewarded trials in the maximum target direction

    % Find which column holds the target centers
    tgt_Center_idx = contains(xds.trial_info_table_header, 'tgtCenter');
    if ~any(tgt_Center_idx)
        tgt_Center_idx = contains(xds.trial_info_table_header, 'tgtCtr');
    end

    % Pull the target centers of each succesful trial
    tgt_cntrs_morn = struct([]);
    for ii = 1:height(rewarded_trial_idx)
        tgt_cntrs_morn{ii,1} = xds.trial_info_table{rewarded_trial_idx(ii), tgt_Center_idx};
    end

    % Convert the centers into polar coordinates
    target_centers_morn = zeros(height(rewarded_trial_idx), 1);
    for ii = 1:height(rewarded_trial_idx)
        target_centers_morn(ii) = sqrt((tgt_cntrs_morn{ii,1}(1,1))^2 + (tgt_cntrs_morn{ii,1}(1,2))^2);
    end

    % Find the number of unique target centers
    unique_targets_morn = unique(target_centers_morn);
    max_targets_morn = max(unique_targets_morn);

    rewarded_trial_idx = rewarded_trial_idx(target_centers_morn == max_targets_morn);

    if ~strcmp(trial_num, 'All')
        if gt(trial_num, length(rewarded_trial_idx))
            fprintf('trial_num cannot exceed %0.f \n', length(rewarded_trial_idx));
            return
        end
    end

else

    % If 'All' was selected
    rewarded_trial_idx = 1:length(xds.trial_result);
    rewarded_trial_idx = rewarded_trial_idx';

end

%% Loop to extract only rewarded trials 
% Rewarded start times
rewarded_start_time = zeros(length(rewarded_trial_idx),1);
for ii = 1:length(rewarded_trial_idx)
    rewarded_start_time(ii) = xds.trial_start_time(rewarded_trial_idx(ii));
end

% Rewarded go-cues
rewarded_gocue_time = zeros(length(rewarded_trial_idx),1);
for ii = 1:length(rewarded_trial_idx)
    rewarded_gocue_time(ii) = xds.trial_gocue_time(rewarded_trial_idx(ii));
end
    
% Rewarded end times
rewarded_end_time = zeros(length(rewarded_trial_idx),1);
for ii = 1:length(rewarded_trial_idx)
    rewarded_end_time(ii) = xds.trial_end_time(rewarded_trial_idx(ii));
end

%% Find the relative times of the succesful trials (in seconds)
start_to_gocue = zeros(length(rewarded_trial_idx),1);
for ii = 1:length(rewarded_trial_idx)
    start_to_gocue(ii) = rewarded_gocue_time(ii) - rewarded_start_time(ii);
end

start_to_end = zeros(length(rewarded_trial_idx),1);
for ii = 1:length(rewarded_trial_idx)
    start_to_end(ii) = rewarded_end_time(ii) - rewarded_start_time(ii);
end

relative_start_time = zeros(length(rewarded_trial_idx),1);
for ii = 1:length(rewarded_trial_idx)
    if ii == 1
        relative_start_time(ii) = 0;
    else
        relative_start_time(ii) = relative_start_time(ii-1) + start_to_end(ii-1) + xds.bin_width;
    end
end

% Find when the go cue took place in each trial
relative_gocue_time = zeros(length(rewarded_trial_idx),1);
for ii = 1:length(rewarded_trial_idx)
    relative_gocue_time(ii) = relative_start_time(ii) + start_to_gocue(ii);
end

% Find when the end of the trial took place
relative_end_time = zeros(length(rewarded_trial_idx),1);
for ii = 1:length(rewarded_trial_idx)
    relative_end_time(ii) = relative_start_time(ii) + start_to_end(ii);
end

%% Getting the spike timestamps based on the behavior timings above

% Extract all the spikes of the unit
trial_spikes = struct([]);
for jj = 1:length(N)
    spikes = xds.spikes{1, N(jj)};
    for ii = 1:length(rewarded_trial_idx)
        trial_spikes{jj,1}{ii, 1} = spikes((spikes > rewarded_start_time(ii)) & ... 
            (spikes < rewarded_end_time(ii)));
    end
end

relative_trial_spikes = trial_spikes;
for jj = 1:length(N)
    for ii = 1:length(rewarded_trial_idx)
        if ii == 1
            relative_trial_spikes{jj,1}{ii,1} = trial_spikes{jj,1}{ii, 1} - rewarded_start_time(ii);
        else
            relative_trial_spikes{jj,1}{ii, 1} = trial_spikes{jj,1}{ii, 1} - ... 
                rewarded_start_time(ii) + relative_end_time(ii-1) + xds.bin_width;
        end
    end
end

%% If Heat Map is selected
if isequal(heat_map, 1)
    %% Binning & averaging the spikes
    
    % Set the number of bins based on the length of each trial
    n_bins = round((rewarded_end_time - rewarded_start_time) / bin_size);
    hist_spikes = struct([]);
    for ss = 1:length(relative_trial_spikes)
        for ii = 1:length(rewarded_trial_idx)
            [hist_spikes{ss,1}{ii, 1}, ~] = histcounts(relative_trial_spikes{ss,1}{ii, 1}, n_bins(ii));
        end
    end

    % Finding the firing rates of the hist spikes
    fr_hists_spikes = struct([]);
    for ss = 1:length(relative_trial_spikes)
        for ii = 1:length(rewarded_trial_idx)
            fr_hists_spikes{ss,1}{ii,1} = hist_spikes{ss,1}{ii,1}/bin_size;
        end
    end

    %% Finding the maximum firing rate of each unit to normalize
    max_fr_per_unit = zeros(length(fr_hists_spikes),1);
    for jj = 1:length(max_fr_per_unit)
        max_idx = zeros(length(rewarded_trial_idx),1);
        for ii = 1:length(rewarded_trial_idx)
            max_idx(ii) = max(fr_hists_spikes{jj,1}{ii,1});
        end
        max_fr_per_unit(jj) = max(max_idx);
    end

    %% Normalizing the firing rate of each unit
    norm_fr_hists_spikes = fr_hists_spikes;
    for ss = 1:length(relative_trial_spikes)
        for ii = 1:length(rewarded_trial_idx)
            norm_fr_hists_spikes{ss,1}{ii,1} = fr_hists_spikes{ss,1}{ii,1} / max_fr_per_unit(ss);
        end
    end

end

%% Define the number of trials that will be plotted
if ~strcmp(trial_num, 'All')
    line_number = trial_num;
else
    line_number = length(rewarded_trial_idx);
end

%% Plot first trials (Top Plot)

consec_raster = figure;
consec_raster.Position = [300 300 750 450];
subplot(211);
hold on

% Setting the y-axis limits
ylim([0, length(N)+1])
ylims = ylim;
% Setting the x-axis limits
xlim([0, relative_end_time(line_number)]);

if isequal(heat_map, 0)
    for jj = 1:length(N)
        for ii = 1:line_number
            % The main raster plot
            plot(relative_trial_spikes{jj,1}{ii, 1}, ones(1, length(relative_trial_spikes{jj,1}{ii, 1}))*jj,... 
                'marker', '.', 'color', 'k', 'markersize', 3, 'linestyle', 'none');
        end
    end
end

if isequal(heat_map, 1)
    colormap('turbo');
    for jj = 1:length(N)
        for ii = 1:line_number
            % Define the time axis
            time_axis = (relative_start_time(ii):bin_size:relative_end_time(ii));
            if length(time_axis) > length(norm_fr_hists_spikes{jj,1}{ii,1})
                time_axis(end) = [];
            end
           % The main raster plot
           imagesc(time_axis, jj, norm_fr_hists_spikes{jj,1}{ii,1});
        end
    end
end
  
%% Line indicating go cue and rewards (Top Plot)

if isequal(trial_lines, 1)
    for ii = 1:line_number
        % Dotted green line indicating beginning of measured window
        line([relative_gocue_time(ii) - time_before_gocue, relative_gocue_time(ii) - time_before_gocue], ... 
            [ylims(1), ylims(2)], 'linewidth',2,'color',[0 0.5 0],'linestyle','--');
        % Solid green line indicating the aligned time
        line([relative_gocue_time(ii), relative_gocue_time(ii)], [ylims(1), ylims(2)], ...
            'linewidth', 2, 'color', [0 0.5 0]);
        % Solid red line indicating the aligned time
        line([relative_end_time(ii), relative_end_time(ii)], [ylims(1), ylims(2)], ...
            'linewidth', 2, 'color', 'r');
    end
end

% Remove the y-axis
yticks([])

% Axes Labels
xlabel('Time (Sec.)', 'FontSize', label_font_size)
ylabel('M1 Neurons', 'FontSize', label_font_size)

if isequal(heat_map, 1)
    heat_label = colorbar;
    heat_label.Ticks = [];
    heat_label.Label.String = 'Firing Rate';
    heat_label.FontSize = legend_font_size;
end

% Titling the top plot
if ~strcmp(trial_num, 'All')
    title(sprintf('First %i Succesful Trials: Neural Firing Rate', trial_num), 'FontSize', title_font_size)
else
    title('All Trials: Neural Firing Rate', 'FontSize', title_font_size)
end

% Only label every other tick
figure_axes = gca;
x_labels = string(figure_axes.XAxis.TickLabels);
y_labels = string(figure_axes.YAxis.TickLabels);
x_labels(2:2:end) = NaN;
y_labels(2:2:end) = NaN;
figure_axes.XAxis.TickLabels = x_labels;
figure_axes.YAxis.TickLabels = y_labels;
% Set ticks to outside
set(figure_axes,'TickDir','out');
% Remove the top and right tick marks
set(figure_axes,'box','off')
% Set The Font
set(figure_axes,'fontname', font_name);

%% Plot the last number of trials (Bottom Plot)

subplot(212);
hold on

% Setting the y-axis limits
ylim([0, length(N)+1])
ylims = ylim;
% Setting the x-axis limits
xlim([relative_start_time(length(relative_end_time) - line_number + 1), relative_end_time(end)]);

if isequal(heat_map, 0)
    for jj = 1:length(N)
        for ii = length(relative_start_time) - line_number + 1:length(relative_start_time)
            % The main raster plot
            plot(relative_trial_spikes{jj,1}{ii, 1}, ones(1, length(relative_trial_spikes{jj,1}{ii, 1}))*jj,... 
                'marker', '.', 'color', 'k', 'markersize', 3, 'linestyle', 'none');
        end
    end
end

if isequal(heat_map, 1)
    colormap('turbo');
    for jj = 1:length(N)
        for ii = length(relative_start_time) - line_number + 1:length(relative_start_time)
            % Define the time axis
            time_axis = (relative_start_time(ii):bin_size:relative_end_time(ii));
            if length(time_axis) > length(norm_fr_hists_spikes{jj,1}{ii,1})
                time_axis(end) = [];
            end
           % The main raster plot
           imagesc(time_axis, jj, norm_fr_hists_spikes{jj,1}{ii,1});
        end
    end
end
        
%% Line indicating go cue and rewards (Bottom Plot)

if isequal(trial_lines, 1)
    for ii = length(relative_start_time) - line_number + 1:length(relative_start_time)
        % Dotted green line indicating beginning of measured window
        line([relative_gocue_time(ii) - time_before_gocue, relative_gocue_time(ii) - time_before_gocue], ... 
            [ylims(1), ylims(2)], 'linewidth',2,'color',[0 0.5 0],'linestyle','--');
        % Solid green line indicating the aligned time
        line([relative_gocue_time(ii), relative_gocue_time(ii)], [ylims(1), ylims(2)], ...
            'linewidth', 2, 'color', [0 0.5 0]);
        % Solid red line indicating the aligned time
        line([relative_end_time(ii), relative_end_time(ii)], [ylims(1), ylims(2)], ...
            'linewidth', 2, 'color', 'r');
    end
end

% Remove the y-axis
yticks([])

% Axes Labels
xlabel('Time (Sec.)', 'FontSize', label_font_size)
ylabel('M1 Neurons', 'FontSize', label_font_size)

if isequal(heat_map, 1)
    heat_label = colorbar;
    heat_label.Ticks = [];
    heat_label.Label.String = 'Firing Rate';
    heat_label.FontSize = legend_font_size;
end

% Titling the top plot
if ~strcmp(trial_num, 'All')
    title(sprintf('Last %i Succesful Trials: Neural Firing Rate', trial_num), 'FontSize', title_font_size)
else
    title('All Trials: Neural Firing Rate', 'FontSize', title_font_size)
end

% Only label every other tick
figure_axes = gca;
x_labels = string(figure_axes.XAxis.TickLabels);
y_labels = string(figure_axes.YAxis.TickLabels);
x_labels(2:2:end) = NaN;
y_labels(2:2:end) = NaN;
figure_axes.XAxis.TickLabels = x_labels;
figure_axes.YAxis.TickLabels = y_labels;
% Set ticks to outside
set(figure_axes,'TickDir','out');
% Remove the top and right tick marks
set(figure_axes,'box','off')
% Set The Font
set(figure_axes,'fontname', font_name);












