function [Alignment_Times] = EventAlignmentTimes(xds, target_dir, target_center, event)

%% Run the function according to the event

if contains(event, 'trial_gocue')
    [Alignment_Times] = GoCueAlignmentTimes(xds, target_dir, target_center);
end

if contains(event, 'task_onset')
    if strcmp(xds.meta.task, 'multi_gadget') || strcmp(xds.meta.task, 'WB')
       [Alignment_Times] = ForceOnsetAlignmentTimes(xds, target_dir, target_center);
    else
        [Alignment_Times] = CursorOnsetAlignmentTimes(xds, target_dir, target_center);
    end
end

if contains(event, 'trial_end')
    [Alignment_Times] = TrialEndAlignmentTimes(xds, target_dir, target_center);
end

if contains(event, 'cursor_onset')
    [Alignment_Times] = CursorOnsetAlignmentTimes(xds, target_dir, target_center);
end

if contains(event, 'cursor_veloc')
    [Alignment_Times] = CursorVelocAlignmentTimes(xds, target_dir, target_center);
end

if contains(event, 'cursor_acc')
    [Alignment_Times] = CursorAccAlignmentTimes(xds, target_dir, target_center);
end

if contains(event, 'force_onset')
    [Alignment_Times] = ForceOnsetAlignmentTimes(xds, target_dir, target_center);
end

if contains(event, 'force_deriv')
    [Alignment_Times] = ForceDerivAlignmentTimes(xds, target_dir, target_center);
end

if contains(event, 'force_max')
    [Alignment_Times] = ForceMaxAlignmentTimes(xds, target_dir, target_center);
end

if contains(event, 'EMG_max')
    [Alignment_Times] = EMGMaxAlignmentTimes(xds, target_dir, target_center);
end

