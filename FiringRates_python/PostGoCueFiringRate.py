# -*- coding: utf-8 -*-

import numpy as np

class PostGoCue_FiringRate():    
    
    def __init__(self, xds, unit_name):
        
        #%% Find the meta info to load the output excel table
        if isinstance(unit_name, int):
            
            from Find_Excel import Find_Excel
            
            output_xds = Find_Excel(xds)
            
            #%% Find the unit of interest
            try:
                unit = output_xds.unit_names[unit_name]
            
                ## Identify the index of the unit
                N = xds.unit_names.index(unit)
            except KeyError:
                ## If the unit doesn't exist
                print(unit + ' does not exist')
                self.mp_fr = float('NaN')
                self.avg_hists_spikes = float('NaN')
                self.all_trials_mp_fr = float('NaN')
                return
            
        elif isinstance(unit_name, str):
            try:
                N = xds.unit_names.index(unit_name)
            except ValueError:
                ## If the unit doesn't exist
                print(unit_name + ' does not exist')
                self.mp_fr = float('NaN')
                self.avg_hists_spikes = float('NaN')
                self.all_trials_mp_fr = float('NaN')
                return
        
        #%% Basic settings, some variable extractions, & definitions
        
        # Extract all the spikes of the unit
        spikes = xds.spikes[N]
        
        before_event = 3
        after_event = 3
        
        # Bin size & number of bins
        bin_size = 0.05
        n_bins = round((after_event + before_event)/bin_size)
        
        # Window to calculate the max firing rate
        window_size = 0.1 / bin_size
        
        # Extract the trial directions
        from Identify_Targets import Identify_Targets
        target_vars = Identify_Targets(xds)
        target_dirs = target_vars.target_dirs
        target_centers = target_vars.target_centers
    
        #%% Indexes for rewarded trials in all directions
        
        # Count the number of directions used
        num_dirs = len(target_dirs)

        self.avg_hists_spikes = []
        
        #%% Begin the loop through all directions
        for jj in range(num_dirs):
            
            #%% Times for rewarded trials
            from GoCueAlignmentTimes import GoCueAlignmentTimes
            rewarded_gocue_time = GoCueAlignmentTimes(xds, target_dirs[jj], target_centers[jj])
            from TrialEndAlignmentTimes import TrialEndAlignmentTimes
            rewarded_end_time = TrialEndAlignmentTimes(xds, target_dirs[jj], target_centers[jj])
            
            #%% Define the output variables
            if jj == 0:
                self.mp_fr = np.zeros(num_dirs)
                self.all_trials_mp_fr = [[] for ii in range(num_dirs)]
        
            #%% Getting the spike timestamps based on the above behavior timings
           
            aligned_spike_timing = [[] for ii in range(len(rewarded_gocue_time))]
            for ii in range(len(rewarded_gocue_time)):
                aligned_spike_timing[ii] = spikes[np.where((spikes > rewarded_gocue_time[ii] - before_event)*
                     (spikes < rewarded_gocue_time[ii] + after_event))]
                
            #%% Binning & averaging the spikes
            hist_spikes = np.zeros((len(rewarded_gocue_time), n_bins))
            for ii in range(len(rewarded_gocue_time)):
                hist_spikes[ii,:] = np.histogram(aligned_spike_timing[ii], n_bins)[0]
                
            # Removing the first & last bins (to remove the histogram error)
            hist_spikes = np.delete(hist_spikes, 0, 1)
            hist_spikes = np.delete(hist_spikes, -1, 1)
            
            # Averaging the hist spikes
            self.avg_hists_spikes.append(np.mean(hist_spikes, 0) / bin_size)
            
            #%% Find the trial lengths
            gocue_to_end = rewarded_end_time - rewarded_gocue_time
            
            #%% Find the 95th percentile of the relative timings
            max_gocue_to_end = np.percentile(gocue_to_end, 5)
            
            #%% Convert the times to fit the bins
            max_end_idx = round(max_gocue_to_end / bin_size)
           
            #%% Calculate the floating average
            # This array starts 3.5 indices (0.175 sec.) after the go-cue and ends 
            # 4.5 indices (0.225 sec.) after the 5th percentile fastest trial
            array = self.avg_hists_spikes[jj][int(round(len(self.avg_hists_spikes[jj]) / 4) + 3):
                                         int(round(len(self.avg_hists_spikes[jj]) / 4) + 4 + max_end_idx)]
            from Sliding_Window import Sliding_Window
            Sliding_Window_vars = Sliding_Window(array, window_size, 1)
            sliding_array = Sliding_Window_vars.sliding_array
            float_avg = np.zeros(len(sliding_array))
            for ii in range(len(sliding_array)):
                float_avg[ii] = np.mean(sliding_array[ii])
                                                                                
            #%% Find the highest average
            max_float_avg = np.nanmax(float_avg)
            
            #%% Defining the output variables

            ## Movement phase firing rate
            self.mp_fr[jj] = max_float_avg

          















    
    
    
    