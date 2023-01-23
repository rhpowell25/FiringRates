# -*- coding: utf-8 -*-

import numpy as np
import math

def GoCueAlignmentTimes(xds, target_dir, target_center):

    #%% Indexes for rewarded trials
    
    tgt_Center_header = xds.trial_info_table_header.index('TgtDistance')
    tgt_Center_idx = np.asarray(xds.trial_info_table[:][tgt_Center_header]).reshape(-1,)
    
    if target_dir == 'NaN' and target_center == 'NaN':
        rewarded_idx = np.argwhere(xds.trial_result == 'R').reshape(-1,)
    elif target_dir == 'NaN' and target_center == 'Max':
        from Find_Max_Indexes import Find_Max_Indexes
        rewarded_idx = Find_Max_Indexes(xds)
    else:
        rewarded_idx = np.argwhere(np.logical_and.reduce((xds.trial_result == 'R', \
              xds.trial_target_dir == target_dir, tgt_Center_idx == target_center))).reshape(-1,)
    
    #%% Loops to extract only rewarded trials
    
    # Go-cue's for succesful trials
    Alignment_Times = np.zeros(len(rewarded_idx),)
    for ii in range(len(rewarded_idx)):
        Alignment_Times[ii] = xds.trial_gocue_time[rewarded_idx[ii]]
        
    # Round to match the neural bin size
    Alignment_Times = np.round(Alignment_Times, abs(math.floor(math.log10(xds.bin_width))))
    
    return Alignment_Times
    