# -*- coding: utf-8 -*-


def EventAlignmentTimes(xds, target_dir, target_center, event):

    #%% Run the function according to the event
    
    if 'trial_gocue' in event:
        from GoCueAlignmentTimes import GoCueAlignmentTimes
        Alignment_Times = GoCueAlignmentTimes(xds, target_dir, target_center)
        
    if 'task_onset' in event:
        if xds._lab_data__meta['task_name'] == 'multi_gadget' or xds._lab_data__meta['task_name'] == 'WB':
            from ForceOnsetAlignmentTimes import ForceOnsetAlignmentTimes
            Alignment_Times = ForceOnsetAlignmentTimes(xds, target_dir, target_center)
        else:
            from CursorOnsetAlignmentTimes import CursorOnsetAlignmentTimes
            Alignment_Times = CursorOnsetAlignmentTimes(xds, target_dir, target_center)
    
    if 'trial_end' in event:
        from TrialEndAlignmentTimes import TrialEndAlignmentTimes
        Alignment_Times = TrialEndAlignmentTimes(xds, target_dir, target_center)
        
    if 'cursor_onset' in event:
        from CursorOnsetAlignmentTimes import CursorOnsetAlignmentTimes
        Alignment_Times = CursorOnsetAlignmentTimes(xds, target_dir, target_center)
    
    if 'force_onset' in event:
        from ForceOnsetAlignmentTimes import ForceOnsetAlignmentTimes
        Alignment_Times = ForceOnsetAlignmentTimes(xds, target_dir, target_center)
        
    
    
    
    
    
    return Alignment_Times
    