# -*- coding: utf-8 -*-

import numpy as np
import math
from GoCueAlignmentTimes import GoCueAlignmentTimes
from TrialEndAlignmentTimes import TrialEndAlignmentTimes
from Sliding_Window import Sliding_Window

def CursorOnsetAlignmentTimes(xds, target_dir, target_center):
    
    #%% Basic settings, some variable extractions, & definitions
    
    # Window to calculate the cursor onset
    window_size = 2 # Bins
    step_size = 1 # Bins
    
    #%% Times for rewarded trials
    rewarded_gocue_time = GoCueAlignmentTimes(xds, target_dir, target_center)
    rewarded_end_time = TrialEndAlignmentTimes(xds, target_dir, target_center)
    
    #%% Extracting cursor position & time during successful trials
    
    # Cursor position & time during each succesful trial
    cursor_p = [[] for ii in range(len(rewarded_gocue_time))] # Cursor position during each succesful trial
    timings = [[] for ii in range(len(rewarded_gocue_time))] # Time points during each succesful trial
    for ii in range(len(rewarded_gocue_time)):
        idx = np.where((xds.time_frame > rewarded_gocue_time[ii])*
             (xds.time_frame < rewarded_end_time[ii]))
        cursor_p[ii] = xds.curs_p[idx][:]
        timings[ii] = xds.time_frame[idx]
        
    #%% Find the vector sum of the cursor position
    
    z_cursor_p = [[] for ii in range(len(rewarded_gocue_time))]
    for ii in range(len(rewarded_gocue_time)):
        z_cursor_p[ii] = np.zeros(len(cursor_p[ii]))
        for dd in range(len(z_cursor_p[ii])):
            z_cursor_p[ii][dd] = math.sqrt(cursor_p[ii][dd][0]**2 + cursor_p[ii][dd][1]**2)
            
    #%% Defines onset time via the maximum cursor position
    
    cursor_onset_idx = np.zeros(len(rewarded_gocue_time))
    # Loop through cursor position
    for ii in range(len(rewarded_gocue_time)):
        Sliding_Vars = Sliding_Window(z_cursor_p[ii], window_size, step_size)
        sliding_avg = Sliding_Vars.sliding_avg
        # Find the peak cursor position
        temp_1 = np.argwhere(sliding_avg == np.nanmax(sliding_avg))[0][0]
        # Find the onset of this peak
        temp_2 = np.argwhere(z_cursor_p[ii][0:temp_1] < np.percentile(z_cursor_p[ii], 15, axis = None))
        if len(temp_2) == 0:
            temp_2 = np.argwhere(z_cursor_p[ii][0:temp_1] == min(z_cursor_p[ii][0:temp_1])).reshape(-1,)
        cursor_onset_idx[ii] = temp_2[-1]
        
    #%% Convert the onset_time_idx array into actual timings in seconds
    
    Alignment_Times = np.zeros(len(timings))
    for ii in range(len(timings)):
        Alignment_Times[ii] = timings[ii][int(cursor_onset_idx[ii])]
        
    return Alignment_Times
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    