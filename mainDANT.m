% Set the path to DANT and settings
path_DANT = '.\DANT'; % The path where DANT is installed
path_settings = '.\settings.json'; % Please make sure the settings in the file are accurate

addpath(path_DANT);
addpath(genpath(fullfile(path_DANT, 'Functions')));

user_settings = jsonc.jsoncDecode(fileread(path_settings)); % Read the settings
tic_start = tic;

%% Run DANT
% load the data
fprintf('Loading %s...\n', user_settings.path_to_data);
load(user_settings.path_to_data);

spikeInfo = preprocessSpikeInfo(user_settings, spikeInfo);

% get necessary information
sessions = [spikeInfo.SessionIndex];
channel_locations = [spikeInfo(1).Xcoords, spikeInfo(1).Ycoords];
channel_shanks = spikeInfo(1).Kcoords(:);
locations = cat(1, spikeInfo.Location);
[ISI_features, AutoCorr_features, PETH_features] = getAllFeatures(spikeInfo);
waveforms_all = cat(3, spikeInfo.Waveform);
waveforms_all = permute(waveforms_all, [3,1,2]);

% motion estimation
features_all_motion_estimation = user_settings.motionEstimation.features;
n_iter_motion_estimation = length(features_all_motion_estimation);

% initialize waveform correction
[waveforms_corrected, initial_Motion] = initializeMotion( ...
    user_settings,...
    waveforms_all,...
    sessions,...
    channel_locations,...
    locations);
Motion = initial_Motion;

% fetch stop_early setting safely
if isfield(user_settings.motionEstimation, 'stop_early')
    stop_early = user_settings.motionEstimation.stop_early;
else
    stop_early = false;
end

resultIter = struct();
for i_iter = 1:n_iter_motion_estimation
    % find nearby pairs
    max_distance = user_settings.motionEstimation.max_distance;
    idx_unit_pairs = getNearbyPairs(max_distance, sessions, locations, Motion);
    
    % compute similarity matrix 
    feature_names = features_all_motion_estimation{i_iter}';
    [similarity_matrix_all, feature_names_all] = computeAllSimilarityMatrix( ...
        user_settings, waveforms_corrected, channel_locations, ISI_features, AutoCorr_features, PETH_features, feature_names, idx_unit_pairs, channel_shanks);

    % iterative HDBSCAN
    idx_features = cellfun(@(x)find(strcmpi(feature_names_all, x)), feature_names);
    [hdbscan_matrix, idx_cluster_hdbscan, similarity_matrix, ~, weights, similarity_thres] = ...
        iterativeClustering(user_settings, path_DANT, similarity_matrix_all(:,:,idx_features), feature_names, idx_unit_pairs, sessions);
    
    % count unique matched unit pairs
    num_matches = nnz(triu(hdbscan_matrix, 1));
    fprintf('[Iteration %d] Found %d matched unit pairs.\n', i_iter, num_matches);

    % stop early if the new motion estimate yields fewer or equal matches
    if stop_early && i_iter > 1 
        if num_matches <= resultIter(i_iter-1).NumMatches
            fprintf('[Iteration %d] Match number decreased or stagnated (%d to %d)! Motion correction ends now.\n',...
                i_iter, resultIter(i_iter-1).NumMatches, num_matches);
            
            if i_iter == 2
                % revert to initial baseline if the first correction failed
                Motion = initial_Motion;
                resultIter = struct([]); % Clear iteration history
            else
                % revert to the last successful motion state (two iterations ago)
                Motion = resultIter(i_iter-2).Motion;
                resultIter = resultIter(1:i_iter-2); 
            end
            
            % recompute waveforms using the reverted optimal motion
            waveforms_corrected = computeCorrectedWaveforms(user_settings, waveforms_all, channel_locations, sessions, locations, Motion);
            break;
        end
    end

    % compute drift
    Motion = computeMotion(user_settings, similarity_matrix, hdbscan_matrix, idx_unit_pairs, similarity_thres, sessions, locations);

    % save the result from this iteration
    resultIter(i_iter).FeatureNames = feature_names;
    resultIter(i_iter).Weights = weights;
    resultIter(i_iter).NumMatches = num_matches; 
    resultIter(i_iter).IdxClusters = idx_cluster_hdbscan;
    resultIter(i_iter).Motion = Motion;

    % compute corrected waveforms
    waveforms_corrected = computeCorrectedWaveforms(user_settings, waveforms_all, channel_locations, sessions, locations, Motion);
end

% save the intermediate result
save(fullfile(user_settings.output_folder, 'resultIter.mat'), 'resultIter', '-nocompression');

% final clustering
% find nearby pairs
max_distance = user_settings.clustering.max_distance;
idx_unit_pairs = getNearbyPairs(max_distance, sessions, locations, Motion);

% compute similarity matrix
[similarity_matrix_all, feature_names_all] = computeAllSimilarityMatrix( ...
    user_settings, waveforms_corrected, channel_locations, ISI_features, AutoCorr_features, PETH_features, feature_names, idx_unit_pairs, channel_shanks);

% iterative HDBSCAN
feature_names = user_settings.clustering.features';
idx_features = cellfun(@(x)find(strcmpi(feature_names_all, x)), feature_names);
[hdbscan_matrix, idx_cluster_hdbscan, similarity_matrix, similarity_all, weights, thres, good_matches_matrix, leafOrder] = ...
    iterativeClustering(user_settings, path_DANT, similarity_matrix_all(:,:,idx_features), feature_names, idx_unit_pairs, sessions);

% auto-curate the result
[hdbscan_matrix_curated, idx_cluster_hdbscan_curated,...
    curation_pairs, curation_types, curation_type_names, num_removal] = ...
    autoCuration(user_settings, hdbscan_matrix, idx_cluster_hdbscan, good_matches_matrix, ...
    sessions, similarity_matrix);

% save the final output
Output = saveToOutput(user_settings, spikeInfo,...
    idx_cluster_hdbscan_curated, hdbscan_matrix_curated, locations, leafOrder, ...
    similarity_matrix, similarity_all, idx_unit_pairs, feature_names, weights, thres, good_matches_matrix,...
    sessions, Motion, 1:length(spikeInfo), tic_start, ...
    curation_pairs, curation_types, curation_type_names, num_removal);

% save the corrected waveforms
save(fullfile(user_settings.output_folder, 'Waveforms.mat'),...
    'waveforms_corrected', '-nocompression');

% save the similarity matrix
if user_settings.save_intermediate_results
    save(fullfile(user_settings.output_folder, 'SimilarityMatrix.mat'), 'similarity_matrix_all', 'feature_names_all', '-nocompression');
end

% plot the result
overviewResults(user_settings, Output);
