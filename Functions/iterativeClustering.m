function [hdbscan_matrix, idx_cluster_hdbscan, similarity_matrix, similarity_all,...
    weights, thres, good_matches_matrix, leafOrder] = ...
    iterativeClustering(user_settings, path_DANT, similarity_matrix_all, feature_names, idx_unit_pairs, sessions)
% ITERATIVECLUSTERING  Iterative HDBSCAN clustering with adaptive feature weighting.
%
% Performs iterative HDBSCAN clustering on unit similarity data.
% - Combines multiple similarity features into a single weighted similarity matrix.
% - Executes HDBSCAN via a Python wrapper for a fixed number of iterations.
% - Updates feature weights between iterations using LDA on matched vs. unmatched pairs.
% - Derives final clusters, similarity threshold, and reliable‐matches adjacency.
%
% Inputs:
%   user_settings             struct
%       .clustering.n_iter         Number of HDBSCAN–LDA iterations.
%       .output_folder             Directory to save settings and outputs.
%       .path_to_python            Path to the Python executable.
%
%   path_DANT            char
%       Path to the DANT repo containing main_hdbscan.py.
%
%   similarity_matrix_all     double (n_unit × n_unit × n_features)
%       Pairwise similarity values for each feature.
%
%   feature_names             cell array of char (1 × n_features)
%       Names of the similarity features.
%
%   idx_unit_pairs            integer (n_pairs × 2)
%       Unit‐pair indices to extract features from similarity_matrix_all.
%
%   sessions                  integer vector (n_unit × 1)
%       Session index for each unit.
%
% Outputs:
%   hdbscan_matrix            logical (n_unit × n_unit)
%       Final cluster adjacency after the last iteration.
%
%   idx_cluster_hdbscan       integer (n_unit × 1)
%       Cluster labels for each unit (−1 for noise).
%
%   similarity_matrix         double (n_unit × n_unit)
%       Weighted sum of feature similarities used for clustering.
%
%   similarity_all            double (n_pairs × n_features)
%       Flattened feature matrix for the given idx_unit_pairs.
%
%   weights                   double (1 × n_features)
%       Learned feature weights from the final LDA.
%
%   thres                     double scalar
%       Similarity threshold for defining good matches.
%
%   good_matches_matrix       logical (n_unit × n_unit)
%       Adjacency of unit pairs exceeding the similarity threshold.
%
%   leafOrder                 integer vector
%       Optimal leaf ordering from hierarchical linkage (if requested).
%
% Date:    20250821  
% Author:  Yue Huang  

n_unit = size(similarity_matrix_all, 1);
n_session = max(sessions);
n_pair = size(idx_unit_pairs, 1);
n_feature = length(feature_names);
assert(n_feature == size(similarity_matrix_all, 3));

idx_pairs_in_matrix = sub2ind([n_unit, n_unit], idx_unit_pairs(:,1), idx_unit_pairs(:,2));

similarity_all = zeros(n_pair, n_feature);
for k = 1:n_feature
    temp = squeeze(similarity_matrix_all(:,:,k));
    similarity_all(:,k) = temp(idx_pairs_in_matrix);
end

weights = ones(1, n_feature)./n_feature;
similarity_matrix = squeeze(sum(similarity_matrix_all.*reshape(weights, 1, 1, n_feature), 3));

for iter = 1:user_settings.clustering.n_iter
    fprintf('Iteration %d starts!\n', iter);

    % HDBSCAN
    distance_matrix = 1./(1 + tanh(similarity_matrix));
    distance_matrix(eye(size(distance_matrix)) == 1) = 0;
    
    HDBSCAB_settings.min_samples = 1; % The number of samples in a neighborhood for a point to be considered as a core point.
    % This includes the point itself. When None, defaults to min_cluster_size.
    HDBSCAB_settings.cluster_selection_epsilon = 0; % A distance threshold. 
    % Clusters below this value will be merged. This is the minimum epsilon allowed.
    
    HDBSCAB_settings.min_cluster_size = 2;
    HDBSCAB_settings.max_cluster_size = n_session;
    HDBSCAB_settings.metric = 'precomputed';
    HDBSCAB_settings.data_folder = user_settings.output_folder;
    
    json_text = jsonencode(HDBSCAB_settings);
    
    fid = fopen(fullfile(user_settings.output_folder, 'HDBSCAN_settings.json'), 'w');
    fwrite(fid, json_text);
    fclose(fid);
    
    writeNPY(distance_matrix, fullfile(user_settings.output_folder, 'DistanceMatrix.npy'));
    
    % run HDBSCAN with Python
    system([fullfile(user_settings.path_to_python), ' ',...
        fullfile(path_DANT, 'Functions/main_hdbscan.py'), ' ',...
        fullfile(user_settings.output_folder, 'HDBSCAN_settings.json')]);
    
    idx_cluster_hdbscan = double(readNPY(fullfile(user_settings.output_folder, 'ClusterIndices.npy')));
    % MATLAB starts from 1
    idx_cluster_hdbscan(idx_cluster_hdbscan >= 0) = idx_cluster_hdbscan(idx_cluster_hdbscan >= 0)+1;
    
    n_cluster = max(idx_cluster_hdbscan);
    hdbscan_matrix = zeros(size(similarity_matrix), 'logical');
    for k = 1:n_cluster
        idx = find(idx_cluster_hdbscan == k);
        for j = 1:length(idx)
            for i = j+1:length(idx)
                hdbscan_matrix(idx(j), idx(i)) = 1;
                hdbscan_matrix(idx(i), idx(j)) = 1;
            end
        end
    end
    
    hdbscan_matrix(eye(n_unit) == 1) = 1;
    is_matched = hdbscan_matrix(idx_pairs_in_matrix);

    if iter ~= user_settings.clustering.n_iter
        % LDA and update weights
        mdl = fitcdiscr(similarity_all, is_matched);
        temp = (mdl.Coeffs(1,2).Linear)';
        weights = temp./sum(temp);
        disp('Weights:');
        disp(strjoin(feature_names, '   '));
        disp(weights);
        
        % update the similarity matrix
        similarity_matrix = squeeze(sum(similarity_matrix_all.*reshape(weights, 1, 1, n_feature), 3));
    end
end

if nargout >= 6
    % set the threshold based on LDA results
    thres = mdl.Coeffs(1,2).Const ./ (-mdl.Coeffs(1,2).Linear(1)) .* weights(1);

    good_matches_matrix = similarity_matrix > thres;
    good_matches_matrix(eye(size(good_matches_matrix)) == 1) = 1;
end

if nargout >= 8
    Z = double(readNPY(fullfile(user_settings.output_folder, 'LinkageMatrix.npy')));
    leafOrder = optimalleaforder(Z, distance_matrix);
end

end