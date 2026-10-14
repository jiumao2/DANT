function [Motion, success, resultIter] = estimateSharedMotion(user_settings, path_DANT, spikeInfo, shanks_data)
% ESTIMATESHAREDMOTION  Estimate common motion using within-shank unit matches.
%
% Uses one set of LDA weights and one similarity threshold across shanks,
% while HDBSCAN clusters each shank separately. Reliable cross-session pairs
% jointly constrain the existing rigid or linear motion model.
%
% Inputs:
%   user_settings  Resolved shared settings from getSharedMotionSettings.
%   path_DANT      DANT installation containing the HDBSCAN Python bridge.
%   spikeInfo      Preprocessed per-unit structures in original unit order.
%   shanks_data    One shank ID per unit, aligned with spikeInfo.
% Outputs:
%   Motion         Final common motion, or zero motion on expected failure.
%   success        True only when a fitted motion state is retained.
%   resultIter     Retained iterations with features, weights, matches and motion.
%
% Writes SharedMotion.mat (Motion, success, reason, settings, resultIter) in
% the resolved output folder. Other intermediates follow existing settings.
% Expected lack of matching constraints emits a warning; other errors propagate.

if ~exist(fullfile(user_settings.output_folder, 'Figures'), 'dir')
    mkdir(fullfile(user_settings.output_folder, 'Figures'));
end
sessions = [spikeInfo.SessionIndex];
n_session = max(sessions);
initial_Motion = struct('Linear', zeros(1, n_session), ...
    'Constant', zeros(1, n_session), 'LinearScale', 0.001);
Motion = initial_Motion;
reason = 'No fitted shared motion was retained.';
resultIter = struct([]);
channel_locations = [spikeInfo(1).Xcoords, spikeInfo(1).Ycoords];
channel_shanks = spikeInfo(1).Kcoords(:);
locations = cat(1, spikeInfo.Location);
[ISI_features, AutoCorr_features, PETH_features] = getAllFeatures(spikeInfo);
waveforms_all = permute(cat(3, spikeInfo.Waveform), [3,1,2]);
waveforms_corrected = waveforms_all;
[feature_sets, n_iter] = getMotionFeatureSets(user_settings);
stop_early = isfield(user_settings.motionEstimation, 'stop_early') && user_settings.motionEstimation.stop_early;

fit_settings = user_settings;
fit_settings.save_intermediate_results = false;
try
    for i_iter = 1:n_iter
        idx_unit_pairs = getNearbyPairs(user_settings.motionEstimation.max_distance, sessions, locations, Motion);
        same_shank = shanks_data(idx_unit_pairs(:,1)) == shanks_data(idx_unit_pairs(:,2));
        idx_unit_pairs = idx_unit_pairs(same_shank(:), :);
        if isempty(idx_unit_pairs)
            error('DANT:InsufficientSharedMatches', 'No within-shank nearby unit pairs are available.');
        end
        feature_names = feature_sets{min(i_iter, numel(feature_sets))}';
        [similarity_all, names_all] = computeAllSimilarityMatrix(user_settings, ...
            waveforms_corrected, channel_locations, ISI_features, AutoCorr_features, ...
            PETH_features, feature_names, idx_unit_pairs, channel_shanks, shanks_data);
        idx_features = cellfun(@(x)find(strcmpi(names_all, x)), feature_names);
        [cluster_matrix, idx_clusters, similarity_matrix, ~, weights, threshold] = ...
            iterativeClustering(user_settings, path_DANT, similarity_all(:,:,idx_features), ...
            feature_names, idx_unit_pairs, sessions, shanks_data);
        num_matches = nnz(triu(cluster_matrix, 1));
        fprintf('[Shared motion - Iteration %d] Found %d matched unit pairs.\n', i_iter, num_matches);
        if stop_early && i_iter > 1 && num_matches <= resultIter(i_iter-1).NumMatches
            if i_iter == 2
                Motion = initial_Motion;
                resultIter = struct([]);
            else
                Motion = resultIter(i_iter-2).Motion;
                resultIter = resultIter(1:i_iter-2);
            end
            break
        end

        idx_matrix = sub2ind(size(similarity_matrix), idx_unit_pairs(:,1), idx_unit_pairs(:,2));
        different_session = sessions(idx_unit_pairs(:,1)) ~= sessions(idx_unit_pairs(:,2));
        good = similarity_matrix(idx_matrix) > threshold & cluster_matrix(idx_matrix) & different_session(:);
        pairs = idx_unit_pairs(good, :);
        if isempty(pairs)
            error('DANT:InsufficientSharedMatches', 'No reliable cross-session pairs are available.');
        end
        % Fix the reference session when checking identifiability of the fit.
        session_pairs = reshape(sessions(pairs), size(pairs));
        incidence = zeros(size(pairs, 1), n_session);
        rows = (1:size(pairs, 1))';
        incidence(sub2ind(size(incidence), rows, session_pairs(:,1))) = -1;
        incidence(sub2ind(size(incidence), rows, session_pairs(:,2))) = 1;
        design = incidence(:,2:end);
        if user_settings.waveformCorrection.linear_correction
            depth = mean([locations(pairs(:,1),2), locations(pairs(:,2),2)], 2);
            design = [design .* (0.001 * depth), design];
        end
        if rank(design) < size(design, 2)
            error('DANT:InsufficientSharedMatches', 'Reliable pairs do not determine the shared motion model for all sessions.');
        end
        Motion = computeMotion(fit_settings, similarity_matrix, cluster_matrix, idx_unit_pairs, threshold, sessions, locations);
        if any(~isfinite([Motion.Linear, Motion.Constant]))
            error('DANT:InsufficientSharedMatches', 'The shared motion fit is not finite.');
        end
        resultIter(i_iter).FeatureNames = feature_names;
        resultIter(i_iter).Weights = weights;
        resultIter(i_iter).SimilarityThreshold = threshold;
        resultIter(i_iter).NumMatches = num_matches;
        resultIter(i_iter).NumReliablePairs = size(pairs, 1);
        resultIter(i_iter).IdxClusters = idx_clusters;
        resultIter(i_iter).Motion = Motion;
        waveforms_corrected = computeCorrectedWaveforms(user_settings, waveforms_all, channel_locations, sessions, locations, Motion);
    end
catch exception
    if ~strcmp(exception.identifier, 'DANT:InsufficientSharedMatches')
        rethrow(exception)
    end
    reason = exception.message;
    Motion = initial_Motion;
    resultIter = struct([]);
end
success = ~isempty(resultIter);
if success
    reason = 'A fitted shared motion state was retained.';
else
    warning('DANT:SharedMotionFailed', '%s Continuing with independent motion estimation.', reason);
end
save(fullfile(user_settings.output_folder, 'SharedMotion.mat'), ...
    'Motion', 'success', 'reason', 'user_settings', 'resultIter', '-v7.3');
end
