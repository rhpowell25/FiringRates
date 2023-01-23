
#%% Import basic packages
import numpy as np
import math
from GoCueAlignmentTimes import GoCueAlignmentTimes
from TrialEndAlignmentTimes import TrialEndAlignmentTimes
from Sliding_Window import Sliding_Window

def ForceOnsetAlignmentTimes(xds, target_dir, target_center):
    
    #%% Basic settings, some variable extractions, & definitions
    
    # Window to calculate the cursor onset
    window_size = 2 # Bins
    step_size = 1 # Bins
    
    #%% Times for rewarded trials
    
    rewarded_gocue_time = GoCueAlignmentTimes(xds, target_dir, target_center)
    rewarded_end_time = TrialEndAlignmentTimes(xds, target_dir, target_center)
    
    #%% Extracting force & time during successful trials
    
    # Force & time during each succesful trial
    force = [[] for ii in range(len(rewarded_gocue_time))] # Force during each succesful trial
    timings = [[] for ii in range(len(rewarded_gocue_time))] # Time points during each succesful trial
    for ii in range(len(rewarded_gocue_time)):
        idx = np.where((xds.time_frame > rewarded_gocue_time[ii])*
             (xds.time_frame < rewarded_end_time[ii]))
        force[ii] = xds.force[idx][:]
        timings[ii] = xds.time_frame[idx]
        
    #%% Sum the two force transducers
    
    z_force = [[] for ii in range(len(rewarded_gocue_time))]
    for ii in range(len(rewarded_gocue_time)):
        if xds._lab_data__meta['task_name'] == 'WB':
            z_force[ii] = np.zeros(len(force[ii]))
            for dd in range(len(z_force[ii])):
                z_force[ii][dd] = math.sqrt(force[ii][dd][0]**2 + force[ii][dd][1]**2)
        else:
            z_force[ii] = force[ii][:,0] + force[ii][:,1]
            
    #%% Defines onset time via the force onset
    
    force_onset_idx = np.zeros(len(rewarded_gocue_time))
    # Loop through force
    for ii in range(len(rewarded_gocue_time)):
        Sliding_Vars = Sliding_Window(z_force[ii], window_size, step_size)
        sliding_avg = Sliding_Vars.sliding_avg
        # Find the peak force
        temp_1 = np.argwhere(sliding_avg == np.nanmax(sliding_avg))[0][0]
        # Find the onset of this peak
        temp_2 = np.argwhere(z_force[ii][0:temp_1] < np.percentile(z_force[ii], 15, axis = None))
        if len(temp_2) == 0:
            temp_2 = np.argwhere(z_force[ii][0:temp_1] == min(z_force[ii][0:temp_1])).reshape(-1,)
        force_onset_idx[ii] = temp_2[-1]
        
    #%% Convert the onset_time_idx array into actual timings in seconds
    
    Alignment_Times = np.zeros(len(timings))
    for ii in range(len(timings)):
        Alignment_Times[ii] = timings[ii][int(force_onset_idx[ii])]
        
    return Alignment_Times
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    