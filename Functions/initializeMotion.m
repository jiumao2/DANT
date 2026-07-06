function [waveforms_corrected, Motion] = initializeMotion(user_settings, waveforms_all,...
    sessions, channel_locations, locations)
% INITIALIZEMOTION  Initialize motion correction from pre-computed drift estimates.
%
% Loads session-wise motion values from a user-specified .npy file and applies
% them to correct unit waveforms. If no motion file is provided, raw waveforms
% are returned unchanged. A one-dimensional motion file is interpreted as rigid
% motion. A two-row motion file is interpreted as linear and constant terms.
%
% Inputs:
%   user_settings           struct
%       .waveformCorrection.path_to_motion   char or string
%           Path to pre-computed motion .npy file. Valid shapes are
%           n_session, 1 x n_session, n_session x 1, 2 x n_session, or
%           n_session x 2. Two-row files store Linear in row 1 and Constant
%           in row 2.
%
%   waveforms_all           double (n_unit × n_channel × n_sample)  
%       Raw waveform snippets for each unit, across channels and time samples
%
%   sessions                integer (n_unit × 1)  
%       Session index for each unit, used to select the appropriate motion vector
%
%   channel_locations       double (n_channel × 2)  
%       X,Y coordinates of each recording channel on the probe
%
%   locations               double (n_unit × 2)  
%       X,Y coordinates of the peak waveform location for each unit
%
% Outputs:
%   waveforms_corrected     double (n_unit × n_channel × n_sample × n_templates)  
%       Corrected waveform templates for each unit under each motion correction template
%
%   Motion                  struct  
%       .LinearScale        double scalar  
%           Global scaling factor for motion (default: 0.001)  
%       .Linear             double vector (n_session × 1)  
%           Per‐session linear coefficients  
%       .Constant           double vector (n_session × 1)  
%           Per‐session offset terms
%
% Date:    20251121
% Author:  Yue Huang

n_session = max(sessions);
linear_scale = 1/1000;
Motion = struct('Linear', zeros(1, n_session), 'Constant', zeros(1, n_session), 'LinearScale', linear_scale);

if ~isfield(user_settings.waveformCorrection, 'path_to_motion') || isempty(user_settings.waveformCorrection.path_to_motion)
    waveforms_corrected = waveforms_all;
    return
end

features_all_motion_estimation = user_settings.motionEstimation.features;
first_feature_set = features_all_motion_estimation;
if iscell(features_all_motion_estimation) && ~isempty(features_all_motion_estimation) && ...
        iscell(features_all_motion_estimation{1})
    first_feature_set = features_all_motion_estimation{1};
end

if ~any(strcmpi(first_feature_set, 'Waveform'))
    error(['When waveformCorrection.path_to_motion is set, the first motionEstimation.features ', ...
        'entry must include "Waveform"; otherwise the manually provided motion is not used ', ...
        'during the first motion-correction clustering round.']);
end

if ~isfile(user_settings.waveformCorrection.path_to_motion)
    error('Path to motion file not found!');
end

% load motion from file
fprintf('Loading pre-computed motion from file: %s\n', user_settings.waveformCorrection.path_to_motion)
motion = readNPY(user_settings.waveformCorrection.path_to_motion);

% check the size of motion
if length(motion) ~= n_session
    error('The size of motion from file is not correct!');
end
if size(motion, 1) ~= 1 && size(motion, 1) ~= 2
    motion = motion';
end

% update Motion
if size(motion, 1) == 1
    Motion.Constant = motion;
else
    Motion.Linear = motion(1,:);
    Motion.Constant = motion(2,:);
end

% compute corrected waveforms and save to Waveforms.mat
waveforms_corrected = computeCorrectedWaveforms(user_settings, waveforms_all, channel_locations, sessions, locations, Motion);

end
