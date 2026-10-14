function [shared_settings, additional_features] = getSharedMotionSettings(user_settings, spikeInfo)
% GETSHAREDMOTIONSETTINGS  Resolve optional multi-shank motion settings.
%
% Returns an empty shared_settings when disabled, when manual motion takes
% precedence, or when fewer than two shanks contain units. additional_features
% lists temporal features needed by the shared and post-shared schedules.
% The input settings and the ordinary motion feature schedule are unchanged.
%
% Inputs:
%   user_settings        struct containing optional sharedMotion settings.
%   spikeInfo            Raw per-unit structures with Waveform and Kcoords.
% Outputs:
%   shared_settings      Settings copy for output_folder/SharedMotion, or [].
%   additional_features  Column cell array of additional feature names.

shared_settings = [];
additional_features = {};
if ~isfield(user_settings, 'sharedMotion') || ...
        ~isfield(user_settings.sharedMotion, 'enabled') || ~user_settings.sharedMotion.enabled
    return
end
if isfield(user_settings.waveformCorrection, 'path_to_motion') && ...
        ~isempty(user_settings.waveformCorrection.path_to_motion)
    warning('DANT:ManualMotionPrecedence', ...
        'path_to_motion is set; skipping shared motion estimation.');
    return
end

shanks = zeros(1, numel(spikeInfo));
for k = 1:numel(spikeInfo)
    [~, channel] = max(max(spikeInfo(k).Waveform, [], 2) - min(spikeInfo(k).Waveform, [], 2));
    shanks(k) = spikeInfo(k).Kcoords(channel);
end
if numel(unique(shanks)) < 2
    return
end

shared_settings = user_settings;
shared_settings.output_folder = fullfile(user_settings.output_folder, 'SharedMotion');
fields = {'features', 'repeat_last_feature_set', 'stop_early'};
for k = 1:numel(fields)
    name = fields{k};
    if isfield(user_settings.sharedMotion, name)
        shared_settings.motionEstimation.(name) = user_settings.sharedMotion.(name);
    end
end
if isfield(user_settings.sharedMotion, 'linear_correction')
    shared_settings.waveformCorrection.linear_correction = user_settings.sharedMotion.linear_correction;
end
feature_sets = shared_settings.motionEstimation.features;
if isfield(user_settings.motionEstimation, 'features_after_shared')
    feature_sets = [feature_sets(:); user_settings.motionEstimation.features_after_shared(:)];
end
for k = 1:numel(feature_sets)
    additional_features = [additional_features; feature_sets{k}(:)]; %#ok<AGROW>
end
additional_features = unique(additional_features, 'stable');
end
