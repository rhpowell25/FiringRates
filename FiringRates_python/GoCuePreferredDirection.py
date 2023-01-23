# -*- coding: utf-8 -*-
from BaselineFiringRate import Baseline_FiringRate
from PostGoCueFiringRate import PostGoCue_FiringRate
import numpy as np

class GoCue_PreferredDirection():    
    
    def __init__(self, xds, unit_name):
        
        #%% End the function if the task is Powergrasp
        if xds._lab_data__meta['task_name'] == 'multi_gadget':
            self.prefdir = 90
            return
        
        #%% Run the baseline & movement phase function
        Baseline_FR_Vars = Baseline_FiringRate(xds, unit_name)
        PostGoCue_FR_Vars = PostGoCue_FiringRate(xds, unit_name)

        #%% Calculate the depth of modulation
        depth_mod = PostGoCue_FR_Vars.mp_fr - Baseline_FR_Vars.bs_fr

        #%% Find the number of target directions
        unique_target_dirs = np.unique(PostGoCue_FR_Vars.target_dirs)

        #%% Find the depth of modulation of the maximum target center in each direction
        max_center_depth_mod = np.zeros(len(unique_target_dirs))
        for ii in range(len(unique_target_dirs)):
            dir_idx = np.argwhere(PostGoCue_FR_Vars.target_dirs == unique_target_dirs[ii]).reshape(-1,)
            target_centers_idx = PostGoCue_FR_Vars.target_centers[dir_idx]
            depth_mod_per_dir = depth_mod[dir_idx]
            max_target_center_idx = np.argwhere(target_centers_idx == max(target_centers_idx)).reshape(-1,)
            max_center_depth_mod[ii] = depth_mod_per_dir[max_target_center_idx]

        #%% Find the maximum depth of modulation & the preferred direction
        max_mod = max(max_center_depth_mod)
        max_mod_idx = np.argwhere(depth_mod == max_mod).reshape(-1,)
        self.prefdir = np.unique(PostGoCue_FR_Vars.target_dirs[max_mod_idx])[0]

        #%% Printing the preferred direction
        
        if isinstance(unit_name, str):
            print(unit_name + "'s preferred direction is " + str(self.prefdir))
        else:
            print("The unit's preferred direction is " + self.prefdir + "°")

    
    
    
    