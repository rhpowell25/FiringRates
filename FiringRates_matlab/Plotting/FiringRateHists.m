function [bsfr_p_val, mpfr_p_val] = FiringRateHists(xds_morn, xds_noon, unit_name, event, fr_phase, Save_Figs)

%% Display the function being used
disp('Firing Rate Histogram Function:');

%% Find the unit of interest
[N] = Find_Unit(xds_morn, unit_name);
unit = xds_morn.unit_names(N);

%% Get the firing rates based on the event
[~, ~, bsfr_morn] = BaselineFiringRate(xds_morn, unit_name);
[~, ~, bsfr_noon] = BaselineFiringRate(xds_noon, unit_name);

[~, ~, mpfr_morn] = ...
    EventPeakFiringRate(xds_morn, unit_name, event);
[~, ~, mpfr_noon] = ...
    EventPeakFiringRate(xds_noon, unit_name, event);

% Extract the target directions & centers
[target_dirs_morn, target_centers_morn] = Identify_Targets(xds_morn);
[target_dirs_noon, target_centers_noon] = Identify_Targets(xds_noon);

%% Some variable extraction & definitions
% How much do you want to expand the axis
axis_expansion = 6;

% Font & plotting specifications
[Plot_Params] = Plot_Parameters;
legend_dims = [0.425 0.35 0.44 0.44];
        
%% Check to see if both sessions use a consistent number of targets

% Find matching targets between the two sessions
[Matching_Idxs_Morn, Matching_Idxs_Noon] = ...
    Match_Targets(target_dirs_morn, target_dirs_noon, target_centers_morn, target_centers_noon);

% Only use the info of target centers conserved between morn & noon
if ~all(Matching_Idxs_Morn) || ~all(Matching_Idxs_Noon)
    disp('Uneven Targets Between Morning & Afternoon');
    target_centers_morn = target_centers_morn(Matching_Idxs_Morn);
    target_dirs_morn = target_dirs_morn(Matching_Idxs_Morn);
    mpfr_morn = pertrial_mpfr_morn(Matching_Idxs_Morn);
    mpfr_noon = pertrial_mpfr_noon(Matching_Idxs_Noon);
end

%% Indexes for rewarded trials in all directions
% Counts the number of directions used
num_dir = length(target_dirs_morn);

%% Peak Firing Rate
if strcmp(fr_phase, 'Peak') || strcmp(fr_phase, 'Both')
    %% Begin the loop through all directions
    for jj = 1:num_dir
    
        hist_figure = figure;
        hist_figure.Position = [250 250 Plot_Params.fig_size Plot_Params.fig_size];
        hold on
    
        % Title
        title(sprintf('Peak Firing Rates, %0.f°, TgtCenter, %0.f - %s', ... 
            target_dirs_morn(jj), target_centers_morn(jj), char(unit)), ...
            'FontSize', Plot_Params.title_font_size)
            
        % Morning & Afternoon Baseline Firing Rates
        histogram(mpfr_morn{jj}, 'EdgeColor', 'k', 'FaceColor', [0.9290, 0.6940, 0.1250])
        histogram(mpfr_noon{jj}, 'EdgeColor', 'k', 'FaceColor', [.5 0 .5])
    
        % Collect the current axis limits
        y_limits = ylim;
        x_limits = xlim;
    
        % Lines indicating the mean
        line([mean(mpfr_morn{jj}) mean(mpfr_morn{jj})], [y_limits(1) y_limits(2) + axis_expansion], ... 
            'LineStyle','--', 'Color', [0.9290, 0.6940, 0.1250], 'LineWidth', 2)
        line([mean(mpfr_noon{jj}) mean(mpfr_noon{jj})], [y_limits(1) y_limits(2) + axis_expansion], ... 
            'LineStyle','--', 'Color', [.5 0 .5], 'LineWidth', 2)
    
        % Labels
        xlabel('Peak Firing Rates (Hz)', 'FontSize', Plot_Params.label_font_size)
        ylabel('Succesful Trials', 'FontSize', Plot_Params.label_font_size)
    
        % Peak firing rate statistics (Unpaired T-Test)
        [~, mpfr_p_val] = ttest2(mpfr_morn{jj}, mpfr_noon{jj});
    
        % Annotation of the p_value
        if round(mpfr_p_val, 3) > 0
            ann_legend = annotation('textbox', legend_dims, 'String', ... 
                strcat('p =', {' '}, mat2str(round(mpfr_p_val, 3))), ... 
                'FitBoxToText', 'on', 'verticalalignment', 'top', ...
                'EdgeColor','none', 'horizontalalignment', 'right');
            ann_legend.FontSize = Plot_Params.legend_size;
            ann_legend.FontName = Plot_Params.font_name;
        end
        if isequal(round(mpfr_p_val, 3), 0)
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
        legend([dummy_yellow, dummy_purple], ... 
            {'Morning', 'Afternoon'}, 'Location', 'northeast', 'FontSize', Plot_Params.legend_size)
        % Remove the legend's outline
        legend boxoff
    
        % Reset the axis limits
        xlim([x_limits(1) - axis_expansion,x_limits(2)] + axis_expansion)
        ylim([y_limits(1),y_limits(2) + axis_expansion])

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
        set(figure_axes,'box','off');
        % Set The Font
        set(figure_axes,'fontname', Plot_Params.font_name);
    
    end % End of target direction loop
else
    mpfr_p_val = NaN;
end

%% Baseline Firing Rate
if strcmp(fr_phase, 'Baseline') || strcmp(fr_phase, 'Both')

    hist_figure = figure;
    hist_figure.Position = [250 250 Plot_Params.fig_size Plot_Params.fig_size];
    hold on

    % Title
    title(sprintf('Baseline Firing Rates, %s', char(unit)), 'FontSize', Plot_Params.title_font_size)
        
    % Morning & Afternoon Baseline Firing Rates
    histogram(bsfr_morn{1}, 'EdgeColor', 'k', 'FaceColor', [0.9290, 0.6940, 0.1250])
    histogram(bsfr_noon{1}, 'EdgeColor', 'k', 'FaceColor', [.5 0 .5])

    % Collect the current axis limits
    y_limits = ylim;
    x_limits = xlim;

    % Lines indicating the mean
    line([mean(bsfr_morn{1}) mean(bsfr_morn{1})], [y_limits(1) y_limits(2) + axis_expansion], ... 
        'LineStyle','--', 'Color', [0.9290, 0.6940, 0.1250], 'LineWidth', 2)
    line([mean(bsfr_noon{1}) mean(bsfr_noon{1})], [y_limits(1) y_limits(2) + axis_expansion], ... 
        'LineStyle','--', 'Color', [.5 0 .5], 'LineWidth', 2)

    % Labels
    xlabel('Baseline Firing Rates (Hz)', 'FontSize', Plot_Params.label_font_size)
    ylabel('Succesful Trials', 'FontSize', Plot_Params.label_font_size)

    % Peak firing rate statistics (Unpaired T-Test)
    [~, bsfr_p_val] = ttest2(bsfr_morn{1}, bsfr_noon{1});

    % Annotation of the p_value
    if round(bsfr_p_val, 3) > 0
        ann_legend = annotation('textbox', legend_dims, 'String', ... 
            strcat('p =', {' '}, mat2str(round(bsfr_p_val, 3))), ... 
            'FitBoxToText', 'on', 'verticalalignment', 'top', ...
            'EdgeColor','none', 'horizontalalignment', 'right');
        ann_legend.FontSize = Plot_Params.legend_size;
        ann_legend.FontName = Plot_Params.font_name;
    end
    if isequal(round(bsfr_p_val, 3), 0)
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
    legend([dummy_yellow, dummy_purple], ... 
        {'Morning', 'Afternoon'}, 'Location', 'northeast', 'FontSize', Plot_Params.legend_size)
    % Remove the legend's outline
    legend boxoff

    % Reset the axis limits
    xlim([x_limits(1) - axis_expansion, x_limits(2)] + axis_expansion)
    ylim([y_limits(1), y_limits(2) + axis_expansion])

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
    set(figure_axes,'box','off');
    % Set The Font
    set(figure_axes,'fontname', Plot_Params.font_name);
else
    bsfr_p_val = NaN;
end

%% Figure Saving
if ~isequal(Save_Figs, 0)
    save_dir = 'C:\Users\rhpow\Desktop\';
    for ii = 1:length(findobj('type','figure'))
        fig_info = get(gca,'title');
        fig_title = get(fig_info, 'string');
        if isempty(fig_title)
            fig_info = sgt;
            fig_title = get(fig_info, 'string');
        end
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




