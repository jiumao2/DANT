function [features_all_motion_estimation, n_iter_motion_estimation] = getMotionFeatureSets(user_settings)
% GETMOTIONFEATURESETS  Resolve feature sets and iteration cap for motion estimation.
%
% Reads the motionEstimation section of user_settings and determines how many
% motion-estimation iterations should be attempted. Legacy settings are
% preserved by default. If repeat_last_feature_set is true, the motion loop can
% continue beyond the explicitly listed feature sets by reusing the final set
% until max_iter is reached or stop_early terminates the loop.
%
% Inputs:
%   user_settings                       struct
%       .motionEstimation.features          cell array
%           Feature sets used for motion estimation in each scheduled round.
%       .motionEstimation.max_iter          double scalar (optional)
%           Maximum number of motion estimation iterations.
%       .motionEstimation.repeat_last_feature_set logical scalar (optional)
%           Whether to reuse the final feature set after the explicit schedule
%           is exhausted.
%
% Outputs:
%   features_all_motion_estimation      cell array
%       Feature sets from user_settings.motionEstimation.features.
%
%   n_iter_motion_estimation            double scalar
%       Maximum number of motion estimation iterations to attempt.
%
% Date:    20260508
% Author:  Yue Huang

features_all_motion_estimation = user_settings.motionEstimation.features;
n_feature_sets = length(features_all_motion_estimation);

if isfield(user_settings.motionEstimation, 'repeat_last_feature_set')
    repeat_last_feature_set = user_settings.motionEstimation.repeat_last_feature_set;
else
    repeat_last_feature_set = false;
end

if isfield(user_settings.motionEstimation, 'max_iter')
    max_iter = user_settings.motionEstimation.max_iter;
elseif repeat_last_feature_set
    max_iter = 15;
else
    max_iter = n_feature_sets;
end

if repeat_last_feature_set
    n_iter_motion_estimation = max_iter;
else
    n_iter_motion_estimation = min(max_iter, n_feature_sets);
end

end
