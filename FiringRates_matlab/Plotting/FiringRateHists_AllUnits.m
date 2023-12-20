function FiringRateHists_AllUnits(xds, event, Save_Figs)

%% Display the function being used
disp('All Units Firing Rate Histogram Function:');

%% Get the firing rates based on the event
unit_names = xds.unit_names;

bs_fr = struct([]);
mp_fr = struct([]);
depth_mod = struct([]);
for ii = 1:length(unit_names)
    [~, ~, bs_fr{ii,1}] = BaselineFiringRate(xds, unit_names{ii});
    [mp_fr{ii,1}, ~, ~] = EventPeakFiringRate(xds, unit_names{ii}, event);
    %depth_mod{ii,1} = mp_fr - bs_fr;
end

% Extract the target directions & centers
[target_dirs, target_centers] = Identify_Targets(xds);

%% Some variable extraction & definitions
% How much do you want to expand the axis
axis_expansion = 1;

% Font & plotting specifications
[Plot_Params] = Plot_Parameters;
        
%% Indexes for rewarded trials in all directions
% Counts the number of directions used
num_dir = length(target_dirs);

%% Begin the loop through all directions
for jj = 1:num_dir

    hist_figure = figure;
    hist_figure.Position = [250 250 Plot_Params.fig_size Plot_Params.fig_size];
    hold on

    % Seperate out the firing rates
    target_depth = zeros(length(depth_mod),1);
    for ii = 1:length(depth_mod)
        target_depth(ii,1) = depth_mod{ii,1}(jj);
    end

    % Title
    title(sprintf('Depth of Modulation, %0.f°, TgtCenter, %0.f', ... 
        target_dirs(jj), target_centers(jj)), 'FontSize', Plot_Params.title_font_size)
        
    % Morning & Afternoon Baseline Firing Rates
    histogram(target_depth, 'binwidth', 2)

    % Collect the current axis limits
    y_limits = ylim;

    % Lines indicating the mean
    line([mean(target_depth) mean(target_depth)], [y_limits(1) y_limits(2) + axis_expansion], ... 
        'LineStyle','--', 'Color', 'k', 'LineWidth', 2)

    % Labels
    xlabel('Depth of Modulation (Hz)', 'FontSize', Plot_Params.label_font_size)
    ylabel('Units', 'FontSize', Plot_Params.label_font_size)

    % Reset the axis limits
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




