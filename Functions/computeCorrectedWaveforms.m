function waveforms_corrected = computeCorrectedWaveforms(user_settings, waveforms_all, channel_locations, sessions, locations, Motion)
% COMPUTECORRECTEDWAVEFORMS  Apply motion‐based correction to waveform templates
%
% computeCorrectedWaveforms generates multiple corrected waveform templates for each unit
% by shifting the waveform extraction depth according to estimated motion parameters.
% For two templates, one uses the minimum and the other the maximum estimated motion shift.
%
% Inputs:
%   user_settings              struct
%       .waveformCorrection.n_templates   integer scalar
%           Number of correction templates to compute
%
%   waveforms_all              double (n_unit × n_channel × n_sample)
%       Raw waveform snippets for each unit, across channels and time samples
%
%   channel_locations          double (n_channel × 2)
%       X,Y coordinates of each recording channel on the probe
%
%   sessions                   integer (n_unit × 1)
%       Session index for each unit, used to select the appropriate motion vector
%
%   locations                  double (n_unit × 2)
%       X,Y coordinates of the peak waveform location for each unit
%
%   Motion                     struct
%       .LinearScale           double scalar
%           Global scaling factor for motion (default: 0.001)
%       .Linear                double vector (n_session × 1)
%           Per‐session linear coefficients
%       .Constant              double vector (n_session × 1)
%           Per‐session offset terms
%
% Outputs:
%   waveforms_corrected        double (n_unit × n_channel × n_sample × n_templates)
%       Corrected waveform templates for each unit under each motion correction template
%
% Date:    20250821
% Author:  Yue Huang

n_unit = size(waveforms_all, 1);
n_channel = size(waveforms_all, 2);
n_sample = size(waveforms_all, 3);
n_templates = user_settings.waveformCorrection.n_templates;

waveforms_corrected = zeros(n_unit, n_channel, n_sample, n_templates);

min_channel_depth = min(channel_locations(:,2));
max_channel_depth = max(channel_locations(:,2));

motion_bottom = Motion.LinearScale*Motion.Linear*min_channel_depth + Motion.Constant;
motion_top = Motion.LinearScale*Motion.Linear*max_channel_depth + Motion.Constant;

min_motion = min([motion_bottom, motion_top]);
max_motion = max([motion_bottom, motion_top]);
fprintf('The range of motion: [%.1f μm ~ %.1f μm]\n', min_motion, max_motion);

% start parallel pool
if ~isfield(user_settings, 'n_jobs') || user_settings.n_jobs ~= 0
    is_parallel = true;
else
    is_parallel = false;
end

if is_parallel && isempty(gcp('nocreate'))
    c = parcluster('local');
    if ~isfield(user_settings, 'n_jobs') || user_settings.n_jobs == -1
        parpool(c.NumWorkers);
    else
        parpool(user_settings.n_jobs);
    end
end

for i_template = 1:n_templates
    Motion_this = Motion;
    if n_templates == 2
        if i_template == 1
            Motion_this.Constant = Motion_this.Constant - min_motion;
        else
            Motion_this.Constant = Motion_this.Constant - max_motion;
        end
    end

    progBar = ProgressBar(n_unit, ...
        'IsParallel', is_parallel, ...
        'Title', 'Computing waveform features', ...
        'UpdateRate', 1 ...
        );
    progBar.setup([], [], []);

    if is_parallel
        parfor k = 1:n_unit
            location_this = locations(k,:);

            dy = Motion_this.LinearScale*Motion_this.Linear(sessions(k))*location_this(2) + Motion_this.Constant(sessions(k));
            location_new = location_this;
            location_new(2) = location_new(2) - dy;

            waveforms_corrected(k,:,:,i_template) = waveformEstimation(...
                squeeze(waveforms_all(k,:,:)), location_this, channel_locations, location_new);

            updateParallel(1);
        end
    else
        for k = 1:n_unit
            location_this = locations(k,:);

            dy = Motion_this.LinearScale*Motion_this.Linear(sessions(k))*location_this(2) + Motion_this.Constant(sessions(k));
            location_new = location_this;
            location_new(2) = location_new(2) - dy;

            waveforms_corrected(k,:,:,i_template) = waveformEstimation(...
                squeeze(waveforms_all(k,:,:)), location_this, channel_locations, location_new);

            progBar([], [], []);
        end
    end
    progBar.release();
end

end