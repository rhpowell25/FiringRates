function OverlapPolarPlot(xds_morn, xds_noon, unit_name, event, Save_Figs)

%% End the function if there is no Y-Limit

max_RLims = RLim(xds_morn, xds_noon, unit_name, event);

if isnan(max_RLims)
    disp("There is no R-Limit")
    return
end

%% Display the function being used
disp('Overlap Polar Plot Function:');

%% Find the unit of interest
[N] = Find_Unit(xds_morn, unit_name);
unit = xds_morn.unit_names(N);

%% Some variable extraction & definitions

% Font specifications
title_font_size = 15;
plot_line_size = 3;
axes_font_size = 20;
r_axes_angle = 45;
axes_line_size = 3;
font_name = 'Arial';

%% Retrieve the movement phase firing rates

[mp_fr_morn, std_mp_morn, ~] = EventPeakFiringRate(xds_morn, unit_name, event);
[mp_fr_noon, std_mp_noon, ~] = EventPeakFiringRate(xds_noon, unit_name, event);

% Extract the target directions & centers
[target_dirs_morn, target_centers_morn] = Identify_Targets(xds_morn);
[target_dirs_noon, target_centers_noon] = Identify_Targets(xds_noon);

%% Check to see if both sessions use a consistent number of directions

% Find matching targets between the two sessions
[Matching_Idxs_Morn, Matching_Idxs_Noon] = ...
    Match_Targets(target_dirs_morn, target_dirs_noon, target_centers_morn, target_centers_noon);

if ~all(Matching_Idxs_Morn) || ~all(Matching_Idxs_Noon)
    disp('Uneven Targets Between Morning & Afternoon');
    % Only use the info of target centers conserved between morn & noon
    mp_fr_morn = mp_fr_morn(Matching_Idxs_Morn);
    mp_fr_noon = mp_fr_noon(Matching_Idxs_Noon);
    std_mp_morn = std_mp_morn(Matching_Idxs_Morn);
    std_mp_noon = std_mp_noon(Matching_Idxs_Noon);
end

%% Seperate the information according to the target centers
% Find the number of unique targets
unique_targets_morn = unique(target_centers_morn)';
unique_targets_noon = unique(target_centers_noon)';

morn_unique_target_idx = zeros(height(target_centers_morn)/length(unique_targets_morn), ... 
    length(unique_targets_morn));
noon_unique_target_idx = zeros(height(target_centers_noon)/length(unique_targets_noon), ... 
    length(unique_targets_noon));

morn_target_dirs_idx = zeros(height(target_dirs_morn)/length(unique_targets_morn), ... 
    length(unique_targets_morn));
noon_target_dirs_idx = zeros(height(target_dirs_noon)/length(unique_targets_noon), ...
    length(unique_targets_noon));

morn_mp_fr_idx = zeros(height(mp_fr_morn)/length(unique_targets_morn),length(unique_targets_morn));
noon_mp_fr_idx = zeros(height(mp_fr_noon)/length(unique_targets_noon),length(unique_targets_noon));

morn_err_mp_idx = zeros(height(std_mp_morn)/length(unique_targets_morn),length(unique_targets_morn));
noon_err_mp_idx = zeros(height(std_mp_noon)/length(unique_targets_noon),length(unique_targets_noon));

for ii = 1:length(unique_targets_morn)
    morn_unique_target_idx(:,ii) = find(target_centers_morn == unique_targets_morn(ii));
    noon_unique_target_idx(:,ii) = find(target_centers_noon == unique_targets_noon(ii));
    
    morn_target_dirs_idx(:,ii) = target_dirs_morn(morn_unique_target_idx(:,ii));
    noon_target_dirs_idx(:,ii) = target_dirs_noon(noon_unique_target_idx(:,ii));
    
    morn_mp_fr_idx(:,ii) = mp_fr_morn(morn_unique_target_idx(:,ii));
    noon_mp_fr_idx(:,ii) = mp_fr_noon(noon_unique_target_idx(:,ii));
    
    morn_err_mp_idx(:,ii) = std_mp_morn(morn_unique_target_idx(:,ii));
    noon_err_mp_idx(:,ii) = std_mp_noon(noon_unique_target_idx(:,ii));
end

%% Making sure the polar plots connect
% Morning
morn_target_dirs_idx(end+1,:) = morn_target_dirs_idx(1,:);
morn_mp_fr_idx(end+1,:) = morn_mp_fr_idx(1,:);
morn_err_mp_idx(end+1,:) = morn_err_mp_idx(1,:);

% Afternoon
noon_target_dirs_idx(end+1,:) = noon_target_dirs_idx(1,:);
noon_mp_fr_idx(end+1,:) = noon_mp_fr_idx(1,:);
noon_err_mp_idx(end+1,:) = noon_err_mp_idx(1,:);

%% Adding & subtracting the error from the firing rates

% Morning
pos_err_mp_morn = morn_mp_fr_idx + morn_err_mp_idx;
neg_err_mp_morn = morn_mp_fr_idx - morn_err_mp_idx;

% Afternoon
pos_err_mp_noon = noon_mp_fr_idx + noon_err_mp_idx;
neg_err_mp_noon = noon_mp_fr_idx - noon_err_mp_idx;

%% Plotting the tuning curves

for kk = 1:length(unique_targets_morn)
    figure

    % Set the error marker shape
    if length(unique(target_dirs_morn)) < 3
        errmrk = '|';
        if isequal(unique(abs(target_dirs_morn)), 90)
            errmrk = '_';
        end
        if isequal(xds_morn.meta.task, 'multi_gadget')
            errmrk = '_';
        end
    else
        errmrk = '.';
        if isequal(xds_morn.meta.task, 'multi_gadget')
            errmrk = '_';
        end
    end
    
    % Set the error marker size / length
    sz = 125;

    % Plot the morning baseline standard error in gold
    polarscatter(deg2rad(morn_target_dirs_idx(:,kk)), pos_err_mp_morn(:,kk), ... 
        sz, 'MarkerEdgeColor', [0.9290, 0.6940, 0.1250], 'Marker', errmrk, 'LineWidth', plot_line_size)
    hold on
    polarscatter(deg2rad(morn_target_dirs_idx(:,kk)), neg_err_mp_morn(:,kk), ... 
        sz, 'MarkerEdgeColor', [0.9290, 0.6940, 0.1250], 'Marker', errmrk, 'LineWidth', plot_line_size)
    % Plot the afternoon baseline standard error in purple
    polarscatter(deg2rad(noon_target_dirs_idx(:,kk)), pos_err_mp_noon(:,kk), ... 
        sz, 'MarkerEdgeColor', [.5 0 .5], 'Marker', errmrk, 'LineWidth', plot_line_size)
    polarscatter(deg2rad(noon_target_dirs_idx(:,kk)), neg_err_mp_noon(:,kk), ... 
        sz, 'MarkerEdgeColor', [.5 0 .5], 'Marker', errmrk, 'LineWidth', plot_line_size)

    % Connect the error bars with lines with a marker in the center
    if length(unique(target_dirs_morn)) == 2 && ~isequal(unique(abs(target_dirs_morn)), 90)
        % Plot the morning baseline firing rate in gold
        polarplot([0,0], [pos_err_mp_morn(1,kk); neg_err_mp_morn(1,kk)], ...
            'LineWidth', plot_line_size, 'color', [0.9290, 0.6940, 0.1250]);
        polarscatter(0, morn_mp_fr_idx(1,kk), sz, [0.9290, 0.6940, 0.1250], 'Marker','.')
        polarplot([pi,pi], [pos_err_mp_morn(2,kk); neg_err_mp_morn(2,kk)], ...
            'LineWidth', plot_line_size, 'color', [0.9290, 0.6940, 0.1250]);
        polarscatter(pi, morn_mp_fr_idx(2,kk), sz, [0.9290, 0.6940, 0.1250], 'Marker','.')
        % Plot the afternoon baseline firing rate in purple
        polarplot([0,0], [pos_err_mp_noon(1,kk); neg_err_mp_noon(1,kk)], ...
            'LineWidth', plot_line_size, 'color', [.5 0 .5]);
        polarscatter(0, noon_mp_fr_idx(1,kk), sz, [.5 0 .5], 'Marker','.')
        polarplot([pi,pi], [pos_err_mp_noon(2,kk); neg_err_mp_noon(2,kk)], ...
            'LineWidth', plot_line_size, 'color', [.5 0 .5]);
        polarscatter(pi, noon_mp_fr_idx(2,kk), sz, [.5 0 .5], 'Marker','.')  
    end

    if length(unique(target_dirs_morn)) == 2 && isequal(unique(abs(target_dirs_morn)), 90)
        % Plot the morning baseline firing rate in gold
        polarplot([deg2rad(morn_target_dirs_idx(1,kk)),deg2rad(morn_target_dirs_idx(1,kk))], ... 
            [pos_err_mp_morn(1,kk); neg_err_mp_morn(1,kk)], ...
            'LineWidth', plot_line_size, 'color', [0.9290, 0.6940, 0.1250]);
        polarplot([deg2rad(morn_target_dirs_idx(2,kk)),deg2rad(morn_target_dirs_idx(2,kk))], ... 
            [pos_err_mp_morn(2,kk); neg_err_mp_morn(2,kk)], ...
            'LineWidth', plot_line_size, 'color', [0.9290, 0.6940, 0.1250]);
        polarscatter(deg2rad(morn_target_dirs_idx(1,kk)), morn_mp_fr_idx(1,kk), ... 
            sz, [0.9290, 0.6940, 0.1250], 'Marker','.')
        polarscatter(deg2rad(morn_target_dirs_idx(2,kk)), morn_mp_fr_idx(2,kk), ... 
            sz, [0.9290, 0.6940, 0.1250], 'Marker','.')
        % Plot the afternoon baseline firing rate in purple
        polarplot([deg2rad(noon_target_dirs_idx(1,kk)),deg2rad(noon_target_dirs_idx(1,kk))], ... 
            [pos_err_mp_noon(1,kk); neg_err_mp_noon(1,kk)], ...
            'LineWidth', plot_line_size, 'color', [.5 0 .5]);
        polarplot([deg2rad(noon_target_dirs_idx(2,kk)),deg2rad(noon_target_dirs_idx(2,kk))], ... 
            [pos_err_mp_noon(2,kk); neg_err_mp_noon(2,kk)], ...
            'LineWidth', plot_line_size, 'color', [.5 0 .5]);
        polarscatter(deg2rad(noon_target_dirs_idx(1,kk)), noon_mp_fr_idx(1,kk), ... 
            sz, [.5 0 .5], 'Marker','.')
        polarscatter(deg2rad(noon_target_dirs_idx(2,kk)), noon_mp_fr_idx(2,kk), ... 
            sz, [.5 0 .5], 'Marker','.')
    end
    
    if length(unique(target_dirs_morn)) == 1
        % Plot the morning baseline firing rate in gold
        polarplot([deg2rad(morn_target_dirs_idx(1,kk)),deg2rad(morn_target_dirs_idx(1,kk))], ... 
            [pos_err_mp_morn(1,kk); neg_err_mp_morn(1,kk)], ...
            'LineWidth', plot_line_size, 'color', [0.9290, 0.6940, 0.1250]);
        polarscatter(deg2rad(morn_target_dirs_idx(1,kk)), morn_mp_fr_idx(1,kk), ... 
            sz, [0.9290, 0.6940, 0.1250], 'Marker','.')
        % Plot the afternoon baseline firing rate in purple
        polarplot([deg2rad(noon_target_dirs_idx(1,kk)),deg2rad(noon_target_dirs_idx(1,kk))], ... 
            [pos_err_mp_noon(1,kk); neg_err_mp_noon(1,kk)], ...
            'LineWidth', plot_line_size, 'color', [.5 0 .5]);
        polarscatter(deg2rad(noon_target_dirs_idx(1,kk)), noon_mp_fr_idx(1,kk), ... 
            sz, [.5 0 .5], 'Marker','.')
    end
    
    % Connect the polar plots if more than one dimensional
    if length(unique(target_dirs_morn)) > 2
        % Plot the morning baseline firing rate in gold
        polarplot((morn_target_dirs_idx(:,kk)*(pi/180)), morn_mp_fr_idx(:,kk), ...
            'LineWidth', plot_line_size, 'Color', [0.9290, 0.6940, 0.1250])
        % Plot the afternoon baseline firing rate in purple
        polarplot((noon_target_dirs_idx(:,kk)*(pi/180)), noon_mp_fr_idx(:,kk), ...
            'LineWidth', plot_line_size, 'Color', [.5 0 .5])
    end
    
    %Set the axis limit
    rlim([0 max_RLims])

    % Label the theta axis
    thetatickformat('degrees')

    %Set the ticks for degrees
    if length(unique(target_dirs_morn)) <= 2
        tick_step = 180;
    end
    
    if length(unique(target_dirs_morn)) >= 3
        tick_step = 90;
    end
    thetaticks(0:tick_step:315)

    % Set the title
    if length(unique_targets_morn) == 1
        title(sprintf('Morning vs. Afternoon, %s', ...
            char(unit)), 'FontSize', title_font_size)
    end
    if length(unique_targets_morn) > 1
        title(sprintf('Morning vs. Afternoon, %s, TgtCenter: %0.1f', ...
            char(unit), unique_targets_morn(kk)), 'FontSize', title_font_size)
    end

    % Only label every other tick
    figure_axes = gca;
    figure_axes.RAxisLocation = r_axes_angle;
    figure_axes.FontWeight = 'Bold';
    figure_axes.RColor = 'k';
    figure_axes.ThetaColor = 'k';
    figure_axes.LineWidth = axes_line_size;
    figure_axes.FontSize = axes_font_size;
    r_labels = string(figure_axes.RAxis.TickLabels);
    r_labels(2:2:end) = NaN;
    figure_axes.RAxis.TickLabels = r_labels;
    % Set The Font
    set(figure_axes,'FontName', font_name);

end

%% Define the save directory & save the figures
if ~isequal(Save_Figs, 0)
    save_dir = 'C:\Users\rhpow\Desktop\';
    for ii = 1:length(findobj('type','figure'))
        fig_info = get(gca,'title');
        fig_title = get(fig_info, 'string');
        fig_title = strrep(fig_title, ':', '');
        fig_title = strrep(fig_title, 'vs.', 'vs');
        fig_title = strrep(fig_title, 'mg.', 'mg');
        fig_title = strrep(fig_title, 'kg.', 'kg');
        fig_title = strrep(fig_title, '.', '_');
        fig_title = strrep(fig_title, '/', '_');
        title '';
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


