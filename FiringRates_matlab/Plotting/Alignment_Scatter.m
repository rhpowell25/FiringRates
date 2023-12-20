function Alignment_Scatter(xds_morn, xds_noon, unit_name, Save_Figs)

%% Build the array as long as each event
events = strings;
events(1) = 'window_trial_gocue';
events(2) = 'window_trial_end';
if strcmp(xds_morn.meta.task, 'WS')
    events(3) = 'window_cursor_onset';
    events(4) = 'window_cursor_veloc';
    events(5) = 'window_cursor_acc';
elseif strcmp(xds_morn.meta.task, 'multi_gadget')
    events(3) = 'window_force_onset';
    events(4) = 'window_force_deriv';
    events(5) = 'window_force_max';
end
events(6) = 'window_EMG_onset';
events(7) = 'window_EMG_max';

depth_morn = zeros(length(events), 1);
depth_noon = zeros(length(events), 1);

% Which targets do you want the mnovement phase firing rate calculated from? ('Max', 'Min', 'All')
tgt_mpfr = 'Max';

% Date
raw_file_name = xds_morn.meta.rawFileName;
xtra_info = extractAfter(raw_file_name, '_');
Date = erase(raw_file_name, strcat('_', xtra_info));

% Monkey
xxtra_info = extractAfter(xtra_info, '_');
Monkey = xds_morn.meta.monkey;

% Task
xxxtra_info = extractAfter(xxtra_info, '_');
Task = erase(xxtra_info, strcat('_', xxxtra_info));

% File Name
file_name = strcat(Date, ',', {' '}, Monkey, ',', {' '}, Task);

%% Extract the target directions & centers
[target_dirs_morn, target_centers_morn] = Identify_Targets(xds_morn);
[target_dirs_noon, target_centers_noon] = Identify_Targets(xds_noon);

%% Run the function for each event
for ii = 1:length(events)

    %% Get the baseline firing rates
    [avg_bsfr_morn, ~, ~, ~] = ... 
        BaselineFiringRate(xds_morn, unit_name);
    [avg_bsfr_noon, ~, ~, ~] = ... 
        BaselineFiringRate(xds_noon, unit_name);

    %% Get the movement phase firing rates
    [avg_mpfr_morn, ~, ~] = ...
        EventPeakFiringRate(xds_morn, unit_name, events(ii));
    [avg_mpfr_noon, ~, ~] = ... 
        EventPeakFiringRate(xds_noon, unit_name, events(ii));

    %% Check to see if both sessions use a consistent number of targets

    % Find matching targets between the two sessions
    [Matching_Idxs_Morn, Matching_Idxs_Noon] = ...
        Match_Targets(target_dirs_morn, target_dirs_noon, target_centers_morn, target_centers_noon);
    
    % Only use the info of target centers conserved between morn & noon
    if ~all(Matching_Idxs_Morn) || ~all(Matching_Idxs_Noon)
        disp('Uneven Targets Between Morning & Afternoon');
        target_centers_morn = target_centers_morn(Matching_Idxs_Morn);
        target_centers_noon = target_centers_noon(Matching_Idxs_Noon);
        target_dirs_morn = target_dirs_morn(Matching_Idxs_Morn);
        target_dirs_noon = target_dirs_noon(Matching_Idxs_Noon);
        avg_mpfr_morn = avg_mpfr_morn(Matching_Idxs_Morn);
        avg_mpfr_noon = avg_mpfr_noon(Matching_Idxs_Noon);
    end

    %% Only look at the preferred direction
    [pref_dir] = PreferredDirection_Morn_v_Noon(xds_morn, xds_noon, unit_name, events(ii), tgt_mpfr);
    
    if strcmp(tgt_mpfr, 'Max')
        pref_dir_tgt_morn = max(target_centers_morn(target_dirs_morn == pref_dir));
        pref_dir_tgt_noon = max(target_centers_noon(target_dirs_noon == pref_dir));
    elseif strcmp(tgt_mpfr, 'Min')
        pref_dir_tgt_morn = min(target_centers_morn(target_dirs_morn == pref_dir));
        pref_dir_tgt_noon = min(target_centers_noon(target_dirs_noon == pref_dir));
    end

    %% Look at the maximum or minimum targets if not using all targets

    tgt_mpfr_morn = avg_mpfr_morn(target_centers_morn == pref_dir_tgt_morn);
    tgt_mpfr_noon = avg_mpfr_noon(target_centers_noon == pref_dir_tgt_noon);

    %% Assign the depths of modulation
    depth_morn(ii) = tgt_mpfr_morn - avg_bsfr_morn;
    depth_noon(ii) = tgt_mpfr_noon - avg_bsfr_noon;
    
end

%% Scatter plotting

% Font & plotting specifications
[Plot_Params] = Plot_Parameters;

% Do you want to label the event? (1 = Yes, 0 = No)
event_label = 1;

% Axis expansion
axis_expansion = 15;

% Marker size
sz = 500;
% Marker shape
marker_shape = '.';
% Marker color
marker_color = 0;

scatter_fig = figure;
scatter_fig.Position = [200 50 Plot_Params.fig_size Plot_Params.fig_size];
hold on

% Set the title
fig_title = strcat(file_name, {' '}, '-', {' '}, unit_name);
title(fig_title, 'FontSize', Plot_Params.title_font_size)

% Label the axis
xlabel('Morning Depth of Modulation (Hz)', 'FontSize', Plot_Params.label_font_size);
ylabel('Afternoon Depth of Modulation (Hz)', 'FontSize', Plot_Params.label_font_size);

for jj = 1:length(events)
    scatter(depth_morn(jj), depth_noon(jj), sz, marker_shape, 'MarkerEdgeColor', ... 
                [marker_color 0 0], 'MarkerFaceColor', [marker_color 0 0], 'LineWidth', 1.5)
    if isequal(event_label, 1)
        text(depth_morn(jj) + 1.5, depth_noon(jj) - 1.5, ...
            extractAfter(events(jj), "window_"), 'Interpreter', 'none');
    end
end

% Calculate the axis limits
min_morn = min(depth_morn);
min_noon = min(depth_noon);
max_morn = max(depth_morn);
max_noon = max(depth_noon);
axis_min = round(min(min_morn, min_noon)/5)*5;
axis_max = round(max(max_morn, max_noon)/5)*5;

% Draw the unity line 
line([axis_min - axis_expansion, axis_max + axis_expansion], ...
    [axis_min - axis_expansion, axis_max + axis_expansion], ... 
    'Color', 'k', 'Linewidth', 0.5, 'Linestyle','--')

% Set the axis
xlim([axis_min - axis_expansion, axis_max + axis_expansion])
ylim([axis_min - axis_expansion, axis_max + axis_expansion])

%% Define the save directory & save the figures
if ~isequal(Save_Figs, 0)
    save_dir = 'C:\Users\rhpow\Desktop\';
    for ii = 1:length(findobj('type','figure'))
        fig_title = strrep(fig_title, ':', '');
        fig_title = strrep(fig_title, 'vs.', 'vs');
        fig_title = strrep(fig_title, 'mg.', 'mg');
        fig_title = strrep(fig_title, 'kg.', 'kg');
        fig_title = strrep(fig_title, '.', '_');
        fig_title = strrep(fig_title, '/', '_');
        %title '';
        if strcmp(Save_Figs, 'All')
            saveas(gcf, fullfile(save_dir, char(fig_title)), 'png')
            saveas(gcf, fullfile(save_dir, char(fig_title)), 'pdf')
            saveas(gcf, fullfile(save_dir, char(fig_title)), 'fig')
        else
            saveas(gcf, fullfile(save_dir, char(fig_title)), Save_Figs)
        end
        close gcf
    end
end






