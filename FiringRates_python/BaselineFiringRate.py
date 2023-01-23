# -*- coding: utf-8 -*-

import numpy as np

class Baseline_FiringRate():    
    
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
                self.bs_fr = float('NaN')
                self.std_bs = float('NaN')
                self.avg_hists_spikes = float('NaN')
                self.all_trials_bs_fr = float('NaN')
                return
            
        elif isinstance(unit_name, str):
            try:
                N = xds.unit_names.index(unit_name)
            except ValueError:
                ## If the unit doesn't exist
                print(unit_name + ' does not exist')
                self.bs_fr = float('NaN')
                self.std_bs = float('NaN')
                self.avg_hists_spikes = float('NaN')
                self.all_trials_bs_fr = float('NaN')
                return
        
        #%% Basic settings, some variable extractions, & definitions
        
        # Extract all the spikes of the unit
        spikes = xds.spikes[N]
        
        # Time before & after the gocue
        before_event = 3
        after_event = 3
        
        # Define period before gocue & end to measure
        time_before_gocue = 0.4
        
        # Bin size & number of bins
        bin_size = 0.05
        n_bins = round((after_event + before_event)/bin_size)
        
        # Extract the trial directions
        from Identify_Targets import Identify_Targets
        target_vars = Identify_Targets(xds)
        target_dirs = target_vars.target_dirs
        target_centers = target_vars.target_centers
        
        # Do you want a baseline firing rate for each target / direction combo? (1 = Yes, 0 = No)
        per_dir_bsfr = 0
        
        #%% Indexes for rewarded trials in all directions

        # Count the number of directions used
        num_dirs = len(target_dirs)

        # Define the output variable
        self.avg_hists_spikes = []
        
        #%% Begin the loop through all directions
        for jj in range(num_dirs):
    
            #%% Times for rewarded trials
            from GoCueAlignmentTimes import GoCueAlignmentTimes
            if per_dir_bsfr != 0:
                rewarded_gocue_time = GoCueAlignmentTimes(xds, target_dirs[jj], target_centers[jj])
            else:
                rewarded_gocue_time = GoCueAlignmentTimes(xds, np.nan, np.nan)
            
            #%% Define the output variables
            if jj == 0 and per_dir_bsfr != 0:
                self.bsfr = np.zeros(num_dirs)
                self.std_bs = np.zeros(num_dirs)
                self.all_trials_bs_fr = [[] for ii in range(num_dirs)]
                
            elif jj == 0 and per_dir_bsfr != 1:
                self.bs_fr = np.zeros(1)
                self.std_bs = np.zeros(1)
                self.all_trials_bs_fr = [[]]
        
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
            
            #%% Firing rate during baseline phase
            baseline_fr = np.zeros(len(rewarded_gocue_time))
            for ii in range(len(rewarded_gocue_time)):
                t_start = rewarded_gocue_time[ii] - time_before_gocue
                t_end = rewarded_gocue_time[ii]
                baseline_fr[ii] = len(np.where((spikes > t_start)*
                     (spikes < t_end))[0]) / (t_end - t_start)

            self.all_trials_bs_fr[jj] = baseline_fr
            
            #%% Defining the output variables

            # Baseline firing rate
            self.bs_fr[jj] = np.mean(baseline_fr)
            # Standard Deviation
            self.std_bs[jj] = np.std(baseline_fr)

            # End the function if you only want one firing rate
            if per_dir_bsfr != 1:
                return
          















    
    
    
    