function [pertrial_fr_morn, pertrial_fr_noon] = ...
    FiringRateHists(xds_morn, xds_noon, unit_name, event, fr_phase, Save_File)

%% Display the function being used
disp('Firing Rate Histogram Function:');

%% Find the unit of interest
[N] = Find_Unit(xds_morn, unit_name);
unit = xds_morn.unit_names(N);

%% Extract the target directions & centers
[target_dirs_morn, target_centers_morn] = Identify_Targets(xds_morn);
[target_dirs_noon, target_centers_noon] = Identify_Targets(xds_noon);

%% Some variable extraction & definitions

% How much do you want to expand the axis
axis_expansion = 6;

% Font & plotting specifications
[Plot_Params] = Plot_Parameters;
legend_dims = [0.425 0.325 0.44 0.44];
        
%% Check to see if both sessions use a consistent number of targets

if ~strcmp(fr_phase, 'Baseline')
    % Find matching targets between the two sessions
    [Matching_Idxs_Morn, Matching_Idxs_Noon] = ...
        Match_Targets(target_dirs_morn, target_dirs_noon, target_centers_morn, target_centers_noon);
    
    % Only use the info of target centers conserved between morn & noon
    if ~all(Matching_Idxs_Morn) || ~all(Matching_Idxs_Noon)
        disp('Uneven Targets Between Morning & Afternoon');
        target_centers_morn = target_centers_morn(Matching_Idxs_Morn);
        target_dirs_morn = target_dirs_morn(Matching_Idxs_Morn);
    end

    % Only use the max target center
    max_idx = target_centers_morn == max(target_centers_morn);
    target_center = target_centers_morn(max_idx);
    target_dir = target_dirs_morn(max_idx);
end

%% Get the firing rates based on the event
% Baseline firing rate
[~, ~, ~, pertrial_bsfr_morn] = BaselineFiringRate(xds_morn, unit_name);
[~, ~, ~, pertrial_bsfr_noon] = BaselineFiringRate(xds_noon, unit_name);

% Peak firing rate
[pertrial_mpfr_morn, pertrial_mpfr_noon, ~] = ...
            EventWindow_Morn_v_Noon(xds_morn, xds_noon, unit_name, target_dir, target_center, event);

% Depth of modulation
pertrial_depth_morn = pertrial_mpfr_morn{1,1} - mean(pertrial_bsfr_morn{1,1});
pertrial_depth_noon = pertrial_mpfr_noon{1,1} - mean(pertrial_bsfr_noon{1,1});

if strcmp(fr_phase, 'Baseline')
    pertrial_fr_morn = pertrial_bsfr_morn{1,1};
    pertrial_fr_noon = pertrial_bsfr_noon{1,1};
elseif strcmp(fr_phase, 'Peak')
    pertrial_fr_morn = pertrial_mpfr_morn{1,1};
    pertrial_fr_noon = pertrial_mpfr_noon{1,1};
elseif strcmp(fr_phase, 'Depth')
    pertrial_fr_morn = pertrial_depth_morn;
    pertrial_fr_noon = pertrial_depth_noon;
end

%% Begin the loop through all directions

hist_figure = figure;
hist_figure.Position = [50 50 Plot_Params.fig_size Plot_Params.fig_size];
hold on

% Axis Editing
figure_axes = gca;
% Set ticks to outside
set(figure_axes,'TickDir','out');
% Remove the top and right tick marks
set(figure_axes,'box','off')
% Set the tick label font size
figure_axes.FontSize = Plot_Params.label_font_size;
% Set The Font
set(figure_axes,'fontname', Plot_Params.font_name);

% Title
if strcmp(fr_phase, 'Baseline')
    Fig_Title = strcat('Baseline Firing Rates,', {' '}, char(unit));
elseif strcmp(fr_phase, 'Peak')
    Fig_Title = strcat('Peak Firing Rates,', {' '}, string(target_dir), ...
        ', TgtCenter,', {' '}, string(target_center), ',', {' '}, char(unit));
elseif strcmp(fr_phase, 'Depth')
    Fig_Title = strcat('Depth of Modulation,', {' '}, string(target_dir), ...
        ', TgtCenter,', {' '}, string(target_center), ',', {' '}, char(unit));
end
title(Fig_Title, 'FontSize', Plot_Params.title_font_size)
    
% Morning & Afternoon Baseline Firing Rates
histogram(pertrial_fr_morn, 'EdgeColor', 'k', 'FaceColor', [0.9290, 0.6940, 0.1250])
histogram(pertrial_fr_noon, 'EdgeColor', 'k', 'FaceColor', [.5 0 .5])

test = nbintest(pertrial_fr_morn, pertrial_fr_noon)

parmhat = nbinfit(pertrial_fr_morn)

test = nbintest(pertrial_bsfr_morn{1}, pertrial_bsfr_noon{1})

test = nbintest(pertrial_mpfr_morn{1}, pertrial_fr_morn)

% Collect the current axis limits
y_limits = ylim;
x_limits = xlim;

% Lines indicating the mean
line([mean(pertrial_fr_morn) mean(pertrial_fr_morn)], ...
    [y_limits(1) y_limits(2) + axis_expansion], 'LineStyle','--', ...
    'Color', [0.9290, 0.6940, 0.1250], 'LineWidth', Plot_Params.mean_line_width)
line([mean(pertrial_fr_noon) mean(pertrial_fr_noon)], ...
    [y_limits(1) y_limits(2) + axis_expansion], 'LineStyle','--', 'Color', ...
    [.5 0 .5], 'LineWidth', Plot_Params.mean_line_width)

% Labels
xlabel('Firing Rates (Hz)', 'FontSize', Plot_Params.label_font_size)
ylabel('Succesful Trials', 'FontSize', Plot_Params.label_font_size)

% Firing rate statistics (Unpaired T-Test)
%[~, fr_p_val] = ttest2(pertrial_fr_morn, pertrial_fr_noon);
% Firing rate statistics (Wilcoxon rank sum test)
[fr_p_val, ~] = ranksum(pertrial_fr_morn, pertrial_fr_noon);

% Annotation of the p_value
if round(fr_p_val, 3) > 0
    ann_legend = annotation('textbox', legend_dims, 'String', ... 
        strcat('p =', {' '}, mat2str(round(fr_p_val, 3))), ... 
        'FitBoxToText', 'on', 'verticalalignment', 'top', ...
        'EdgeColor','none', 'horizontalalignment', 'right');
    ann_legend.FontSize = Plot_Params.legend_size;
    ann_legend.FontName = Plot_Params.font_name;
end
if isequal(round(fr_p_val, 3), 0)
    ann_legend = annotation('textbox', legend_dims, 'String', ... 
        strcat('p <', {' '}, '0.001'), ... 
        'FitBoxToText', 'on', 'verticalalignment', 'top', ...
        'EdgeColor','none', 'horizontalalignment', 'right');
    ann_legend.FontSize = Plot_Params.legend_size;
    ann_legend.FontName = Plot_Params.font_name;
end

% Plot dummy points for the legend
dummy_yellow = scatter(-1, -1, 's', 'filled', 'Color', [0.9290, 0.6940, 0.1250]);
dummy_purple = scatter(-1.5, -1.5, 's', 'filled', 'Color', [.5 0 .5]);
% Legend
[~, icons] = legend([dummy_yellow, dummy_purple], ... 
    {'Morning', 'Afternoon'}, 'Location', 'northeast', 'FontSize', Plot_Params.legend_size);
icons = findobj(icons,'Type','patch');
icons = findobj(icons,'Marker','none','-xor');
set(icons,'MarkerSize', Plot_Params.legend_size);
% Remove the legend's outline
legend boxoff

% Reset the axis limits
xlim([x_limits(1) - axis_expansion,x_limits(2)] + axis_expansion)
ylim([y_limits(1),y_limits(2) + axis_expansion])

% Only label every other tick
%x_labels = string(figure_axes.XAxis.TickLabels);
%y_labels = string(figure_axes.YAxis.TickLabels);
%x_labels(2:2:end) = NaN;
%y_labels(2:2:end) = NaN;
%figure_axes.XAxis.TickLabels = x_labels;
%figure_axes.YAxis.TickLabels = y_labels

%% Save the file if selected
Save_Figs(Fig_Title, Save_File)


