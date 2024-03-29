function PolarPlot(xds, unit_name, event, max_RLims, Save_File)

%% Display the function being used
disp('Polar Plot Function:');

%% Find the unit of interest
[N] = Find_Unit(xds, unit_name);
unit = xds.unit_names(N);

%% Some variable extraction & definitions

% Font & plotting specifications
[Plot_Params] = Plot_Parameters;
r_axes_angle = 45;

if ~isequal(Save_File, 0)
    close all
end

% Add the session information to the save title
if contains(xds.meta.rawFileName, 'Pre')
    session_save_title = '(Morn)';
elseif contains(xds.meta.rawFileName, 'Post')
    session_save_title = '(Noon)';
end

%% Retrieve the baseline and movement phase firing rates
[mp_fr, std_mp, ~] = EventPeakFiringRate(xds, unit_name, event);
[bs_fr, std_bs, ~] = BaselineFiringRate(xds, unit_name);

% Extract the target directions & centers
[target_dirs, target_centers] = Identify_Targets(xds);

%% Seperate the information according to the target centers
% Find the number of unique targets
unique_targets = unique(target_centers);

unique_target_idx = zeros(height(target_centers)/length(unique_targets),length(unique_targets));
target_dirs_idx = zeros(height(target_dirs)/length(unique_targets),length(unique_targets));
mp_fr_idx = zeros(height(mp_fr)/length(unique_targets),length(unique_targets));
std_mp_idx = zeros(height(std_mp)/length(unique_targets),length(unique_targets));
for ii = 1:length(unique_targets)
    unique_target_idx(:,ii) = find(target_centers == unique_targets(ii));
    target_dirs_idx(:,ii) = target_dirs(unique_target_idx(:,ii));
    mp_fr_idx(:,ii) = mp_fr(unique_target_idx(:,ii));
    std_mp_idx(:,ii) = std_mp(unique_target_idx(:,ii));
end

if isequal(length(bs_fr), length(mp_fr))
    bs_fr_idx = zeros(height(bs_fr)/length(unique_targets),length(unique_targets));
    std_bs_idx = zeros(height(std_bs)/length(unique_targets),length(unique_targets));
    for ii = 1:length(unique_targets)
        bs_fr_idx(:,ii) = bs_fr(unique_target_idx(:,ii));
        std_bs_idx(:,ii) = std_bs(unique_target_idx(:,ii));
    end
else
    % Make the polar plot a circle if the bsfr is nonspecific
    target_dirs_bs_idx = linspace(0, 360, 50)';
    bs_fr_idx = ones(50,1) * bs_fr;
    std_bs_idx = ones(50,1) * std_bs;
end

%% Making sure the polar plots connect

if isequal(length(bs_fr), length(mp_fr))
    bs_fr_idx(end+1,:) = bs_fr_idx(1,:);
    std_bs_idx(end+1,:) = std_bs_idx(1,:);
end

target_dirs_idx(end+1,:) = target_dirs_idx(1,:);
mp_fr_idx(end+1,:) = mp_fr_idx(1,:);
std_mp_idx(end+1,:) = std_mp_idx(1,:);

%% Adding & subtracting the error from the firing rates

pos_std_bs = bs_fr_idx + std_bs_idx;
neg_std_bs = bs_fr_idx - std_bs_idx;
pos_std_mp = mp_fr_idx + std_mp_idx;
neg_std_mp = mp_fr_idx - std_mp_idx;

%% Plotting the tuning curves

for jj = 1:height(unique_targets)
   
    figure

    % Set the error marker shape
    if length(unique(target_dirs)) < 3
        errmrk = '|';
        if isequal(unique(abs(target_dirs)), 90)
            errmrk = '_';
        end
        if isequal(xds.meta.task, 'multi_gadget')
            errmrk = '_';
        end
    else
        errmrk = '.';
        if isequal(xds.meta.task, 'multi_gadget')
            errmrk = '_';
        end
    end
    
    % Set the error marker size / length
    sz = 150;

    %% Standard Error

    % Plot the standard error of the baseline firing rate in light green
    if isequal(length(bs_fr), length(mp_fr))
        polarscatter(deg2rad(target_dirs_idx(:,jj)), pos_std_bs(:,jj), sz, ... 
            'MarkerEdgeColor', [0.4660, 0.6740, 0.1880], 'Marker',errmrk, ....
            'LineWidth', Plot_Params.mean_line_with)
        hold on
        polarscatter(deg2rad(target_dirs_idx(:,jj)), neg_std_bs(:,jj), sz, ... 
            'MarkerEdgeColor', [0.4660, 0.6740, 0.1880], 'Marker',errmrk, ...
            'LineWidth', Plot_Params.mean_line_with)
    else
        polarplot((deg2rad(target_dirs_bs_idx)), pos_std_bs, 'LineWidth', Plot_Params.mean_line_with, ...
            'LineStyle', '--', 'Color', [0.4660, 0.6740, 0.1880])
        hold on
        polarplot((deg2rad(target_dirs_bs_idx)), neg_std_bs, 'LineWidth', Plot_Params.mean_line_with, ...
            'LineStyle', '--', 'Color', [0.4660, 0.6740, 0.1880])
    end

    % Plot the standard error of the movement phase firing rate in red
    polarscatter(deg2rad(target_dirs_idx(:,jj)), pos_std_mp(:,jj), sz, ... 
        'MarkerEdgeColor', [0.6350, 0.0780, 0.1840], 'Marker',errmrk, 'LineWidth', Plot_Params.mean_line_with)
    polarscatter(deg2rad(target_dirs_idx(:,jj)), neg_std_mp(:,jj), sz, ... 
        'MarkerEdgeColor', [0.6350, 0.0780, 0.1840], 'Marker',errmrk, 'LineWidth', Plot_Params.mean_line_with)

    %% Connect the error bars if 1-dimensional

    if height(unique(target_dirs)) == 2 && ~isequal(unique(abs(target_dirs)), 90)
        % Plot the movement phase firing rate in red
        polarplot([0,0], [pos_std_mp(1,jj); neg_std_mp(1,jj)], ...
            'LineWidth', Plot_Params.mean_line_with, 'color', [0.6350, 0.0780, 0.1840]);
        polarscatter(0, mp_fr_idx(1,jj), sz, [0.6350, 0.0780, 0.1840], 'Marker','.')
        polarplot([pi,pi], [pos_std_mp(2,jj); neg_std_mp(2,jj)], ...
            'LineWidth', Plot_Params.mean_line_with, 'color', [0.6350, 0.0780, 0.1840]);
        polarscatter(pi, mp_fr_idx(2,jj), sz, [0.6350, 0.0780, 0.1840], 'Marker','.')
        % Plot the baseline firing rate in light green
        polarplot([0,0], [pos_std_bs(1,jj); neg_std_bs(1,jj)], ...
            'LineWidth', Plot_Params.mean_line_with, 'color', [0.4660, 0.6740, 0.1880]);
        polarscatter(0, bs_fr_idx(1), sz, [0.4660, 0.6740, 0.1880], 'Marker','.')
        polarplot([pi,pi], [pos_std_bs(2,jj); neg_std_bs(2,jj)], ...
            'LineWidth', Plot_Params.mean_line_with, 'color', [0.4660, 0.6740, 0.1880]);
        polarscatter(pi, bs_fr_idx(2), sz, [0.4660, 0.6740, 0.1880], 'Marker','.')
    end

    if height(unique(target_dirs)) == 2 && isequal(unique(abs(target_dirs)), 90)
        % Plot the movement phase firing rate in dark red
        polarplot([deg2rad(target_dirs_idx(1)),deg2rad(target_dirs_idx(1))], [pos_std_mp(1,jj); neg_std_mp(1,jj)], ...
            'LineWidth', Plot_Params.mean_line_with, 'color', [0.6350, 0.0780, 0.1840]);
        polarplot([deg2rad(target_dirs_idx(2)),deg2rad(target_dirs_idx(2))], [pos_std_mp(2,jj); neg_std_mp(2,jj)], ...
            'LineWidth', Plot_Params.mean_line_with, 'color', [0.6350, 0.0780, 0.1840]);
        polarscatter(deg2rad(target_dirs_idx(1)), mp_fr_idx(1,jj), sz, [0.6350, 0.0780, 0.1840], 'Marker','.')
        polarscatter(deg2rad(target_dirs_idx(2)), mp_fr_idx(2,jj), sz, [0.6350, 0.0780, 0.1840], 'Marker','.')
        %Plot the baseline firing rate in light green
        polarplot([deg2rad(target_dirs_idx(1)),deg2rad(target_dirs_idx(1))], [pos_std_bs(1,jj); neg_std_bs(1,jj)], ...
            'LineWidth', Plot_Params.mean_line_with, 'color', [0.4660, 0.6740, 0.1880]);
        polarplot([deg2rad(target_dirs_idx(2)),deg2rad(target_dirs_idx(2))], [pos_std_bs(2,jj); neg_std_bs(2,jj)], ...
            'LineWidth', Plot_Params.mean_line_with, 'color', [0.4660, 0.6740, 0.1880]);
        polarscatter(deg2rad(target_dirs_idx(1)), bs_fr_idx(1,jj), sz, [0.4660, 0.6740, 0.1880], 'Marker','.')
        polarscatter(deg2rad(target_dirs_idx(2)), bs_fr_idx(2,jj), sz, [0.4660, 0.6740, 0.1880], 'Marker','.')
    end
    
    if height(unique(target_dirs)) == 1
        % Plot the movement phase firing rate in dark red
        polarplot([deg2rad(target_dirs_idx(1)),deg2rad(target_dirs_idx(1))], [pos_std_mp(1,jj); neg_std_mp(1,jj)], ...
            'LineWidth', Plot_Params.mean_line_with, 'color', [0.6350, 0.0780, 0.1840]);
        polarscatter(deg2rad(target_dirs_idx(1)), mp_fr_idx(1,jj), sz, [0.6350, 0.0780, 0.1840], 'Marker','.')
        % Plot the baseline firing rate in light green
        if isequal(length(bs_fr), length(mp_fr))
            polarplot([deg2rad(target_dirs_idx(1)),deg2rad(target_dirs_idx(1))], [pos_std_bs(1,jj); neg_std_bs(1,jj)], ...
                'LineWidth', Plot_Params.mean_line_with, 'color', [0.4660, 0.6740, 0.1880]);
            polarscatter(deg2rad(target_dirs_idx(1)), bs_fr_idx(1,jj), sz, [0.4660, 0.6740, 0.1880], 'Marker','.')
        end
    end
    
    %% Connect the polar plots if 2-dimensional

    if height(unique(target_dirs)) > 2
        % Plot the movement phase firing rate in dark red
        polarplot(deg2rad(target_dirs_idx(:,jj)), mp_fr_idx(:,jj), ...
            'LineWidth', Plot_Params.mean_line_with, 'Color', [0.6350, 0.0780, 0.1840])
        % Plot the baseline firing rate in light green
        if isequal(length(bs_fr), length(mp_fr))
            polarplot(deg2rad(target_dirs_idx(:,jj)), bs_fr_idx(:,jj), ... 
                'LineWidth', Plot_Params.mean_line_with, 'Color', [0.4660, 0.6740, 0.1880])
        end
    end

    if ~isequal(length(bs_fr), length(mp_fr))
        % Plot the baseline firing rate in light green
        polarplot(deg2rad(target_dirs_bs_idx), bs_fr_idx, ...
            'LineWidth', Plot_Params.mean_line_with, 'Color', [0.4660, 0.6740, 0.1880])
    end
    
    % Set the axis limit
    rlim([0 max_RLims])

    % Label the theta axis
    thetatickformat('degrees')

    % Set the ticks for degrees (theta)
    if height(unique(target_dirs)) <= 2
        tick_step = 180;
    end
    if height(unique(target_dirs)) >= 3
        tick_step = 90;
    end
    thetaticks(0:tick_step:315)

    % Titling the polar plot
    Fig_Title = strcat(char(unit), ', TgtCenter At', {' '}, unique_targets(jj));
    title(Fig_Title, 'FontSize', Plot_Params.title_font_size)

    % Only label every other tick
    figure_axes = gca;
    figure_axes.RAxisLocation = r_axes_angle;
    figure_axes.FontWeight = 'Bold';
    figure_axes.RColor = 'k';
    figure_axes.ThetaColor = 'k';
    figure_axes.LineWidth = Plot_Params.axis_line_width;
    figure_axes.FontSize = Plot_Params.axis_font_size;
    r_labels = string(figure_axes.RAxis.TickLabels);
    r_labels(2:2:end) = NaN;
    figure_axes.RAxis.TickLabels = r_labels;
    % Set The Font
    set(figure_axes,'fontname', Plot_Params.font_name);

    %% Save the file if selected
    Fig_Title = strcat(Fig_Title, {' '}, session_save_title);
    Save_Figs(Fig_Title, Save_File)

end



