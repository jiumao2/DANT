function [waveforms_corrected, Motion] = initializeMotion(user_settings, waveforms_all,...
    sessions, channel_locations, locations)
% INITIALIZEMOTION  Initialize motion correction from pre-computed drift estimates.
%
% Loads session-wise motion values from a user-specified .npy file and applies
% them to correct unit waveforms. If no motion file is provided, raw waveforms
% are returned unchanged. The function constructs a Motion struct with
% constant offsets assuming rigid motion.s
%
% Inputs:
%   user_settings           struct
%       .waveformCorrection.path_to_motion   char or string
%           Path to pre-computed motion .npy file (one value per session).
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

if ~isfile(user_settings.waveformCorrection.path_to_motion)
    error('Path to motion file not found!');
end

% load motion from file
motion = readNPY(user_settings.waveformCorrection.path_to_motion);

% check the size of motion
if length(motion) ~= n_session
    error('The size of motion from file is not correct!');
end
if size(motion, 1) ~= 1
    motion = motion';
end

% update Motion
Motion.Constant = motion;

% compute corrected waveforms and save to Waveforms.mat
waveforms_corrected = computeCorrectedWaveforms(user_settings, waveforms_all, channel_locations, sessions, locations, Motion);

end