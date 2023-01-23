# -*- coding: utf-8 -*-

import os
import numpy as np
import pandas as pd
from GoCuePreferredDirection import GoCue_PreferredDirection

class GoCue_Window():    
    
    def __init__(self, xds, unit_name):
        
        #%% Find the meta info to load the output excel table
        if isinstance(unit_name, int):
            # Date
            file_name = xds.file_name
            split_info = file_name.split("_", 1)
            trial_date = split_info[0]
            
            # Task
            if xds._lab_data__meta['task_name'] == 'multi_gadget':
                trial_task = 'PG'
            elif xds._lab_data__meta['task_name'] == 'WS':
                trial_task = 'WS'
                
            # Monkey
            monkey_name = xds._lab_data__meta['monkey_name']
            
            # File path
            base_excel_dir = 'C:/Users/rhpow/Documents/Work/Northwestern/Excel Data/'
            # List of all files
            dir_list = os.listdir(base_excel_dir)
            
            # Selected file index
            selec_file_idx = np.nonzero(map(lambda x: trial_date + '_' + monkey_name + '_' + trial_task in x, dir_list))[0][0]
            
            output_xds = pd.read_excel(base_excel_dir + dir_list[selec_file_idx])
            
            #%% Find the unit of interest
            try:
                unit = output_xds.unit_names[unit_name]
            
                ## Identify the index of the unit
                N = xds.unit_names.index(unit)
            except KeyError:
                ## If the unit doesn't exist
                print(unit + ' does not exist')
                self.max_float_avg_idx = float('NaN')
                self.bin_size = float('NaN')
                self.pref_dir = float('NaN')
                return
            
        elif isinstance(unit_name, str):
            try:
                N = xds.unit_names.index(unit_name)
            except ValueError:
                ## If the unit doesn't exist
                print(unit_name + ' does not exist')
                self.max_float_avg_idx = float('NaN')
                self.bin_size = float('NaN')
                self.pref_dir = float('NaN')
                return
        
        #%% Basic settings, some variable extractions, & definitions
        
        # Extract all spikes of the unit
        spikes = xds.spikes[N]
        
        # Time before & after the gocue
        before_event = 1
        after_event = 3
        self.bin_size = 0.05
        n_bins = round((after_event + before_event)/self.bin_size)
        
        # Window to calculate max firing rate
        after_window = 0.1
        
        end_window_idx = after_window / self.bin_size
        
        # Run the preferred direction function
        prefdir = GoCue_PreferredDirection(xds, unit_name)
        self.pref_dir = prefdir.prefdir
        
        # Index for rewarded trials in the preferred direction
        total_rewarded_idx = np.argwhere(np.in1d(xds.trial_result == 'R', xds.trial_target_dir == self.pref_dir)).reshape(-1,)
            
        #%% Find the number of targets in that particular direction
        try:
            tgt_Center_idx = xds.trial_info_table_header.index('tgtCenter')
        except ValueError:
            tgt_Center_idx = xds.trial_info_table_header.index('tgtCtr')
            
        # Pull the target center coordinates of each succesful trial
        tgt_cntrs = []
        for ii in range(len(total_rewarded_idx)):
            tgt_cntrs.append(xds.trial_info_table[tgt_Center_idx][total_rewarded_idx[ii]])
            
        # Convert the the cartesian coordinates into polar coordinates
        target_cntrs = np.zeros(len(total_rewarded_idx))
        for ii in range(len(total_rewarded_idx)):
            target_cntrs[ii] = (tgt_cntrs[ii][0][0]**2 + tgt_cntrs[ii][1][0]**2)**0.5
            
        # Find the maximum target center
        max_tgt_cntr = max(target_cntrs)
            
        #%% Redefine the rewarded_idx according to the target center
        
        rewarded_idx = total_rewarded_idx[np.asarray(np.where(target_cntrs == max_tgt_cntr)).reshape(-1,)]
        
        #%% Loops to extract only rewarded trials
        # End times for succesful trials
        rewarded_end_time = np.zeros(len(rewarded_idx))
        for ii in range(len(rewarded_idx)):
            rewarded_end_time[ii] = xds.trial_end_time[rewarded_idx[ii]]
            
        # Go-cue's for succesful trials
        rewarded_gocue_time = np.zeros(len(rewarded_idx))
        for ii in range(len(rewarded_idx)):
            rewarded_gocue_time[ii] = xds.trial_gocue_time[rewarded_idx[ii]]
                    
        #%% Skip the function if less than 5 succesful trials in that direction

        if len(rewarded_idx) < 5:
            print('Not enough succesful trials in the maximally tuned direction')
            return
       
        #%% Getting the spike timestamps based on the above behavior timings
       
        aligned_spike_timing = [[] for ii in range(len(rewarded_idx))]
        for ii in range(len(rewarded_idx)):
            aligned_spike_timing[ii] = spikes[np.where((spikes > rewarded_gocue_time[ii] - before_event)*
                 (spikes < rewarded_gocue_time[ii] + after_event))]
                
        # Finding the absolute timing
        absolute_spike_timing = [[] for ii in range(len(rewarded_idx))]
        for ii in range(len(rewarded_idx)):
            absolute_spike_timing[ii] = aligned_spike_timing[ii] - rewarded_gocue_time[ii]
            
        #%% Binning & averaging the spikes
        hist_spikes = np.zeros((len(rewarded_idx), n_bins))
        for ii in range(len(rewarded_idx)):
            hist_spikes[ii,:] = np.histogram(absolute_spike_timing[ii], n_bins)[0]
            
        # Removing the first & last bins (to remove the histogram error)
        hist_spikes = np.delete(hist_spikes, 0, 1)
        hist_spikes = np.delete(hist_spikes, -1, 1)
        
        # Averaging the hist spikes
        avg_hists_spikes = np.mean(hist_spikes, 0) / self.bin_size
        
        #%% Find the trial lengths
        gocue_to_end = rewarded_end_time - rewarded_gocue_time
        
        #%% Find the 95th percentile of the trial lengths
        max_gocue_to_end = np.percentile(gocue_to_end, 5)
        
        #%% Convert the times to fit the bins
        max_end_idx = round(max_gocue_to_end / self.bin_size)
        
        #%% Calculate the floating average
        
        float_avg = np.zeros(max_end_idx)
        for ii in range(len(float_avg)):
            float_avg[ii] = np.mean(avg_hists_spikes[int(round(len(avg_hists_spikes) / 4) + 2 + ii):
                                                              int(round(len(avg_hists_spikes) / 4) + 2 + ii + end_window_idx)])
                                                                            
        #%% Find where the highest average was calculated
        max_float_avg = max(float_avg)
        self.max_float_avg_idx = np.argwhere(float_avg == max_float_avg).reshape(-1,)
        
        self.max_float_avg_idx = self.max_float_avg_idx[0] + round(len(avg_hists_spikes) / 4 + 3)
        
        #%% Print the maximum firing rate in that window
        print('The max firing rate is ' + str(round(max_float_avg, 2)))
        
        #%% Display the measured window
        print('The movement phase window is centered on ' + str(-before_event + (self.max_float_avg_idx*self.bin_size)) + ' seconds')
                                
















    
    
    
    