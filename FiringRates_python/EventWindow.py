#%% Import basic packages
import numpy as np

class Event_Window():    
    
    def __init__(self, xds, unit_name, target_dir, target_center, event):
        
        #%% Find the unit of interest
        from Find_Unit import Find_Unit
        N = Find_Unit(xds, unit_name)
        
        #%% Load the excel file
        if unit_name != 'NaN':
            if not isinstance(unit_name, str):
                from Find_Excel import Find_Excel
                xds_output = Find_Excel(xds)
                
                #%% Find the unit of interest
                try:
                    unit = xds_output.unit_names[unit_name - 1]
                    N = xds.unit_names.index(unit)
                except KeyError:
                    N = 'NaN'
            else:
                try:
                    N = xds.unit_names.index(unit_name)
                except KeyError:
                    N = 'NaN'
        else:
            N = 'NaN'
                    
        #%% End the function with NaN output variables if the unit doesn't exist

        if N == 'NaN':
            # If the unit doesn't exist
            print('Unit does not exist')
            self.avg_hists_spikes = 'NaN'
            self.max_fr_time = 'NaN'
            self.bin_size = 'NaN'
            return
        
        #%% Basic settings, some variable extractions, & definitions
        
        # Extract all spikes of the unit
        spikes = xds.spikes[N]
        
        # Time before & after the event
        before_event = 3
        after_event = 3
        
        # Binning information
        bin_size = 0.04
        n_bins = int((after_event + before_event)/bin_size)
        bin_edges = np.linspace(-before_event, after_event, n_bins)
        
        # Window to calculate the max firing rate
        window_size = 4 # Bins
        step_size = 1 # Bins
            
        #%% Times for rewarded trials
        from EventAlignmentTimes import EventAlignmentTimes
        rewarded_gocue_time = EventAlignmentTimes(xds, target_dir, target_center, 'trial_gocue')
        rewarded_end_time = EventAlignmentTimes(xds, target_dir, target_center, 'trial_end')
        Alignment_Times = EventAlignmentTimes(xds, target_dir, target_center, event)
       
        #%% Getting the spike timestamps based on the above behavior timings
       
        aligned_spike_timing = [[] for ii in range(len(rewarded_gocue_time))]
        for ii in range(len(rewarded_gocue_time)):
            aligned_spike_timing[ii] = spikes[np.where((spikes > Alignment_Times[ii] - before_event)*
                 (spikes < Alignment_Times[ii] + after_event))]
                
        # Finding the absolute timing
        absolute_spike_timing = [[] for ii in range(len(rewarded_gocue_time))]
        for ii in range(len(rewarded_gocue_time)):
            absolute_spike_timing[ii] = aligned_spike_timing[ii] - rewarded_gocue_time[ii]
            
        #%% Binning & averaging the spikes
        hist_spikes = np.zeros((len(rewarded_gocue_time), n_bins - 1))
        for ii in range(len(rewarded_gocue_time)):
            hist_spikes[ii,:] = np.histogram(absolute_spike_timing[ii], bin_edges)[0]
            
        # Removing the first bin (for alignment)
        hist_spikes = np.delete(hist_spikes, 0, 1)
        
        # Averaging the hist spikes
        avg_hists_spikes = np.mean(hist_spikes, 0) / bin_size
        
        #%% Find the trial lengths
        gocue_to_end = rewarded_end_time - rewarded_gocue_time
        event_to_end = rewarded_end_time - Alignment_Times
        
        #%% Find the 5th percentile of the trial lengths
        max_gocue_to_end = np.percentile(gocue_to_end, 5)
        
        #%% Find the 90th percentile of the trial lengths
        max_event_to_end = np.percentile(event_to_end, 90)
        
        #%% Convert the times to fit the bins
        max_gocue_idx = round(max_gocue_to_end / bin_size)
        
        if 'gocue' in event: # Start moving average 5 indices (0.2 sec) after the gocue
            max_gocue_idx = -5
            
        max_end_idx = round(max_event_to_end / bin_size)
        
        #%% Calculate the floating average
        # This array starts after the 5th percentile go-cue
        # and ends after the 90th percentile trial end
        try:
            array = avg_hists_spikes[int(len(avg_hists_spikes) / 2 - max_gocue_idx - 1) : \
                                     int(len(avg_hists_spikes) / 2 + max_end_idx - 1)]
        except:
            array = avg_hists_spikes[int(len(avg_hists_spikes) / 2 - max_gocue_idx - 1) : \
                                     int(len(avg_hists_spikes) - ((window_size / bin_size) / 2) - 1)]
        
        from Sliding_Window import Sliding_Window
        Sliding_Window_vars = Sliding_Window(array, window_size, step_size)
        float_avg = Sliding_Window_vars.sliding_avg
        array_idxs = Sliding_Window_vars.array_idxs
         
        #%% Find where the highest average was calculated
        max_float_avg = np.nanmax(float_avg)
        max_fr_idx = np.where(float_avg == max_float_avg)
        
        max_array_idxs = array_idxs[int(max_fr_idx[0])]
        
        center_max_fr_idx = max_array_idxs[int(np.ceil(len(max_array_idxs) / 2))] + \
                                          len(avg_hists_spikes) / 2 - max_gocue_idx - 1
        
        #%% Print the maximum firing rate in that window
        print('The max firing rate is ' + str(round(max_float_avg, 2)))
        
        #%% Display the measured window
        max_fr_time = (-before_event) + (center_max_fr_idx*bin_size)
        print('The movement phase window is centered on ' + str(max_fr_time) + ' seconds')
                                
        #%% Save the necessary variables
        self.avg_hists_spikes = avg_hists_spikes
        self.max_fr_time = max_fr_time
        self.bin_size = bin_size














    
    
    
    