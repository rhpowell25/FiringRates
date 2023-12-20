
%% Loading the morning and afternoon files
close all
clear
clc

% Which targets do you want the mnovement phase firing rate calculated from? ('Max', 'Min', 'All')
tgt_mpfr = 'Max';
Monkey = 'Pancake';
Drug_Choice = 'Con';

%% Define the experiments that will be examined 

% Dates, Tasks, & Dosages
Dates = strings;
Tasks = strings;
Drug_Dose = strings;

if strcmp(Monkey, 'Pancake')
    if strcmp(Drug_Choice, 'Con')
        % Display the Drug name
        disp('Control:');
        Dates{1,1} = '20220921';
        Tasks{1,1} = 'WS';
        Drug_Dose{1,1} = 'N/A';
        %Dates{1,1} = '20220921';
        %Tasks{1,1} = 'PG';
        %Drug_Dose{1,1} = 'N/A';
    end
    if strcmp(Drug_Choice, 'Caff')
        % Display the Drug name
        disp('Caffeine:');
        Dates{1,1} = '20220907';
        Tasks{1,1} = 'PG';
        Drug_Dose{1,1} = 5.4;
        Dates{2,1} = '20220907';
        Tasks{2,1} = 'WS';
        Drug_Dose{2,1} = 5.4;
    end
    if strcmp(Drug_Choice, 'Cyp')
        % Display the Drug name
        disp('Cyproheptadine:');
        Dates{1,1} = '20220916';
        Tasks{1,1} = 'PG';
        Drug_Dose{1,1} = 0.4;
    end
    if strcmp(Drug_Choice, 'Tiz')
        % Display the Drug name
        disp('Tizanidine:');
        Dates{1,1} = '20220729';
        Tasks{1,1} = 'PG';
        Drug_Dose{1,1} = 'Unknown';
    end
end

if strcmp(Monkey, 'Pop')
    if strcmp(Drug_Choice, 'Caff')
        % Display the Drug name
        disp('Caffeine:');
        Dates{1,1} = '20210610';
        Tasks{1,1} = 'WS';
        Drug_Dose{1,1} = 5.8;
        Dates{2,1} = '20210617';
        Tasks{2,1} = 'WS';
        Drug_Dose{2,1} = 6.9;
        Dates{3,1} = '20210617';
        Tasks{3,1} = 'PG';
        Drug_Dose{3,1} = 6.9;
        Dates{4,1} = '20220304';
        Tasks{4,1} = 'PG';
        Drug_Dose{4,1} = 6.8;
        Dates{5,1} = '20220308';
        Tasks{5,1} = 'PG';
        Drug_Dose{5,1} = 6.3;
    end
    
    if strcmp(Drug_Choice, 'Lex')
        % Display the Drug name
        disp('Escitalopram:');
        Dates{1,1} = '20210813';
        Tasks{1,1} = 'PG';
        Drug_Dose{1,1} = '0.9 - 1.4';
        Dates{2,1} = '20210902';
        Tasks{2,1} = 'PG';
        Drug_Dose{2,1} = 1.0;
        Dates{3,1} = '20210902';
        Tasks{3,1} = 'WS';
        Drug_Dose{3,1} = 1.0;
        Dates{4,1} = '20210917';
        Tasks{4,1} = 'PG';
        Drug_Dose{4,1} = 1.5;
        Dates{5,1} = '20210917';
        Tasks{5,1} = 'WS';
        Drug_Dose{5,1} = 1.5;
    end
    
    if strcmp(Drug_Choice, 'Cyp')
        % Display the Drug name
        disp('Cyproheptadine:');
        Dates{1,1} = '20210623';
        Tasks{1,1} = 'WS';
        Drug_Dose{1,1} = 0.5;
        Dates{2,1} = '20210623';
        Tasks{2,1} = 'PG';
        Drug_Dose{2,1} = 0.5;
        Dates{3,1} = '20211001';
        Tasks{3,1} = 'PG';
        Drug_Dose{3,1} = 0.9;
        Dates{4,1} = '20211001';
        Tasks{4,1} = 'WS';
        Drug_Dose{4,1} = 0.9;
        Dates{5,1} = '20211020';
        Tasks{5,1} = 'PG';
        Drug_Dose{5,1} = 0.8;
        Dates{6,1} = '20211020';
        Tasks{6,1} = 'WS';
        Drug_Dose{6,1} = 0.8;
    end
    
    if strcmp(Drug_Choice, 'Con')
        % Display the Drug name
        disp('Control:');
        Dates{1,1} = '20210713';
        Tasks{1,1} = 'PG';
        Drug_Dose{1,1} = 'N/A';
        Dates{2,1} = '20210722';
        Tasks{2,1} = 'PG';
        Drug_Dose{2,1} = 'N/A';
        Dates{3,1} = '20210722';
        Tasks{3,1} = 'WS';
        Drug_Dose{3,1} = 'N/A';
        Dates{4,1} = '20210922';
        Tasks{4,1} = 'PG';
        Drug_Dose{4,1} = 'N/A';
        Dates{5,1} = '20220214';
        Tasks{5,1} = 'PG';
        Drug_Dose{5,1} = 'N/A';
    end
end

if strcmp(Monkey, 'Groot')
    if strcmp(Drug_Choice, 'Cyp')
        % Display the Drug name
        disp('Caffeine:');
        Dates{1,1} = '20210402';
        Tasks{1,1} = 'WM';
        Drug_Dose{1,1} = 0.5;
    end
end

if strcmp(Monkey, 'Groot')
    if strcmp(Drug_Choice, 'Caff')
        % Display the Drug name
        disp('Caffeine:');
        Dates{1,1} = '20210304';
        Tasks{1,1} = 'PG';
        Drug_Dose{1,1} = 6.9;
        Dates{2,1} = '20210331';
        Tasks{2,1} = 'WS';
        Drug_Dose{2,1} = 5.3;
    end
end

if strcmp(Monkey, 'Mihili')
    if strcmp(Drug_Choice, 'Cyp')
        % Display the Drug name
        disp('Cyproheptadine:');
        Dates{1,1} = '20140623';
        Tasks{1,1} = 'CO';
        Drug_Dose{1,1} = 0.8;
    end
end

if strcmp(Monkey, 'Jaco')
    if strcmp(Drug_Choice, 'Lex')
        % Display the Drug name
        disp('Escitalopram:');
        Dates{1,1} = '20140617';
        Tasks{1,1} = 'WB';
        Drug_Dose{1,1} = 0.3;
    end
    if strcmp(Drug_Choice, 'Con')
        % Display the Drug name
        disp('Control:');
        Dates{1,1} = '20140621';
        Tasks{1,1} = 'WB';
        Drug_Dose{1,1} = 'N/A';
    end
end

if strcmp(Monkey, 'Jango')
    if strcmp(Drug_Choice, 'Lex')
        % Display the Drug name
        disp('Escitalopram:');
        Dates{1,1} = '20140613';
        Tasks{1,1} = 'WB';
        Drug_Dose{1,1} = 0.28;
    end
    if strcmp(Drug_Choice, 'Cyp')
        % Display the Drug name
        disp('Cyproheptadine:');
        Dates{1,1} = '20140615';
        Tasks{1,1} = 'WB';
        Drug_Dose{1,1} = 0.91;
    end
end

%% Loop through the different experiments
for xx = 1:length(Dates)

    % Load the relevant xds file
    xds_morn = Load_XDS(Monkey, Dates{xx,1}, Tasks{xx,1}, 'Morn');
    xds_noon = Load_XDS(Monkey, Dates{xx,1}, Tasks{xx,1}, 'Noon');

    % Process the xds files
    [xds_morn, xds_noon] = Process_XDS(xds_morn, xds_noon);

    xds_excel = Load_Excel(Dates{xx,1}, Monkey, Tasks{xx,1}, tgt_mpfr);

    unit_names = xds_excel.unit_names;

    %% Save directory

    % Define the save folder
    save_folder = strcat(Dates{xx,1}, '_', Tasks{xx,1});

    % Define the save directory
    figure_dir = 'C:\Users\rhpow\Documents\Work\Northwestern\Figures\';
    drug_save_dir = strcat(figure_dir, Monkey, '_', Drug_Choice, '\');
    if ~exist(drug_save_dir, 'dir')
        mkdir(fullfile(drug_save_dir));
    end
    trial_save_dir = strcat(drug_save_dir, save_folder, '\Single Unit Figs\');
    if ~exist(trial_save_dir, 'dir')
        mkdir(fullfile(trial_save_dir));
    end

    %% Plotting & Saving Parameters

    % Select the event to align to:
    % trial_gocue, window_trial_gocue, ...
    % trial_end, window_trial_end, ...
    % force_max, window_force_max, ... 
    % window_force_deriv, force_deriv, ...
    % cursor_veloc, window_cursor_veloc, ...
    % cursor_acc, window_cursor_acc, ...
    % EMG_max, window_EMG_max
    event = 'window_trial_gocue';

    % Decide whether or not to plot (1 = Yes; 0 = No)
    Plot_Figs = 1;
    % Save the figures to desktop? ('pdf', 'png', 'fig', 0 = No)
    Save_File = 'png';

    %% Loop through all units
    for jj = 1:length(unit_names)

        %% Plot the unit summary's
    
        Unit_Summary(xds_morn, xds_noon, unit_names{jj}, 0)

        Fig_Title = strcat(unit_names{jj}, {' '}, '(Unit_Summary)');
        if ~strcmp(Save_File, 'All')
            saveas(gcf, fullfile(trial_save_dir , char(Fig_Title)), Save_File)
        end
        if strcmp(Save_File, 'All')
            saveas(gcf, fullfile(trial_save_dir , Fig_Title), 'png')
            saveas(gcf, fullfile(trial_save_dir , Fig_Title), 'pdf')
            saveas(gcf, fullfile(trial_save_dir , Fig_Title), 'fig')
        end
        close gcf

        %% Plot the trial summary's
    
        Trial_Summary(xds_morn, xds_noon, unit_names{jj}, 0)

        Fig_Title = strcat(unit_names{jj}, {' '}, '(Trial_Summary)');
        % Save the file if selected
        Save_Figs(Fig_Title, Save_File)

    end % End of unit loop

end













