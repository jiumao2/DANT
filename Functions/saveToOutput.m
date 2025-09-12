function Output = saveToOutput(user_settings, spikeInfo,...
    idx_clusters, cluster_matrix, locations, leafOrder, ...
    similarity_matrix, similarity_all, idx_unit_pairs, similarity_names, weights, thres, good_matches_matrix,...
    sessions, Motion, idx_units, tic_start, ...
    curation_pairs, curation_types, curation_type_names, num_removal)
% SAVETOOUTPUT  Create and save Output struct with clustering and similarity results.
%
% This function assembles clustering labels, similarity metrics, curation history,
% and metadata into an Output struct, then writes it to Output.mat in the specified
% output folder and prints a summary to the command window.
%
% Inputs:
%   user_settings              struct  
%       Analysis parameters and I/O settings, including .output_folder  
%
%   spikeInfo                  struct array (NumUnits × 1)  
%       Per‐unit data with optional fields Session, ISI, AutoCorr, PETH, Xcoords, Ycoords  
%
%   idx_clusters               integer vector (NumUnits × 1)  
%       Cluster label assigned to each unit  
%
%   cluster_matrix             logical or double (NumUnits × NumUnits)  
%       Adjacency matrix of unit co‐membership before curation  
%
%   locations                  double (NumUnits × 2 or 3)  
%       [x,y(,z)] coordinates of each unit’s waveform peak  
%
%   leafOrder                  integer vector (NumUnits × 1)  
%       Order of units after hierarchical leaf sorting  
%
%   similarity_matrix          double (NumUnits × NumUnits)  
%       Final similarity adjacency matrix  
%
%   similarity_all             double (P × M)  
%       Raw similarity values for each of P unit pairs and M features  
%
%   idx_unit_pairs             integer matrix (P × 2)  
%       Indices of unit pairs corresponding to rows of similarity_all  
%
%   similarity_names           cell (1 × M) of char  
%       Names of similarity features used in similarity_all  
%
%   weights                    double (M × 1)  
%       Weights applied to each similarity feature  
%
%   thres                      double scalar or vector  
%       Threshold(s) used to define good matches  
%
%   good_matches_matrix        logical (NumUnits × NumUnits)  
%       Binary mask of pairwise similarities above threshold  
%
%   sessions                   integer vector (NumUnits × 1)  
%       Session index for each unit  
%
%   Motion                     struct  
%       Motion parameters with fields LinearScale, Linear, Constant  
%
%   idx_units                  integer vector (NumUnits × 1)  
%       Original unit indices before sorting  
%
%   tic_start                  double scalar  
%       Start time returned by tic, used to compute runtime  
%
%   curation_pairs             integer matrix (Q × 2)  
%       Unit pairs removed or split during curation  
%
%   curation_types             integer vector (1 × Q)  
%       Curation action types (1 = removal; 2 = split)  
%
%   curation_type_names        cell (1 × K) of char  
%       Names of curation types  
%
%   num_removal                integer scalar  
%       Total number of units removed by auto‐curation  
%
% Outputs:
%   Output                     struct with fields:
%       NumClusters            integer scalar  total clusters after curation  
%       NumUnits               integer scalar  total units processed  
%       IdxUnit                integer vector  original unit indices (NumUnits × 1)  
%       Locations              double array    unit coordinates (NumUnits × 2 or 3)  
%       IdxSort                integer vector  leaf‐sorted order (NumUnits × 1)  
%       IdxCluster             integer vector  final cluster labels (NumUnits × 1)  
%       SimilarityMatrix       double matrix    final adjacency (NumUnits × NumUnits)  
%       SimilarityAll          double matrix    raw similarity values (P × M)  
%       SimilarityPairs        integer matrix   unit pairs (P × 2)  
%       SimilarityNames        cell array       names of features (1 × M)  
%       SimilarityWeights      double vector    feature weights (M × 1)  
%       SimilarityThreshold    double            threshold(s) used  
%       GoodMatchesMatrix      logical matrix   thresholded adjacency  
%       ClusterMatrix          logical matrix   pre‐curation adjacency  
%       MatchedPairs           integer matrix   linked unit pairs (Q × 2)  
%       CurationPairs          integer matrix   curated unit pairs (Q × 2)  
%       CurationTypes          integer vector   curation action types (1 × Q)  
%       CurationTypeNames      cell array       names of curation types  
%       CurationNumRemoval     integer scalar   number of removals  
%       Params                 struct           copy of user_settings  
%       NumSession             integer scalar   number of distinct sessions  
%       Sessions               integer vector   session index per unit  
%       Motion                 struct           motion parameters per session  
%       SessionNames           cell array       (optional) session labels  
%       RunTime                double scalar    elapsed time in seconds  
%       DateTime               char             timestamp of save operation  
%
% Date:    20250821  
% Author:  Yue Huang

% get matched_pairs
[idx_row, idx_col] = ind2sub(size(cluster_matrix), find(cluster_matrix == 1));
idx_good = find(idx_col > idx_row);
matched_pairs = [idx_row(idx_good), idx_col(idx_good)];

Output = struct();
Output.NumClusters = max(idx_clusters);
Output.NumUnits = length(idx_clusters);
Output.IdxUnit = idx_units;
Output.Locations = locations; % NumUnits x 3;
Output.IdxSort = leafOrder;
Output.IdxCluster = idx_clusters;
Output.SimilarityMatrix = similarity_matrix; % the output similarity
Output.SimilarityAll = similarity_all;
Output.SimilarityPairs = idx_unit_pairs; % the pairs used to compute similarity_all
Output.SimilarityNames = similarity_names;
Output.SimilarityWeights = weights;
Output.SimilarityThreshold = thres;
Output.GoodMatchesMatrix = good_matches_matrix;
Output.ClusterMatrix = cluster_matrix;
Output.MatchedPairs = matched_pairs;

Output.CurationPairs = curation_pairs;
Output.CurationTypes = curation_types;
Output.CurationTypeNames = curation_type_names;
Output.CurationNumRemoval = num_removal;

Output.Params = user_settings;
Output.NumSession = max(sessions);
Output.Sessions = sessions;
Output.Motion = Motion;

if isfield(spikeInfo, 'Session')
    Output.SessionNames = {spikeInfo.Session};
end

Output.RunTime = toc(tic_start);
Output.DateTime = datestr(datetime('now'));

save(fullfile(user_settings.output_folder, 'Output.mat'), 'Output', '-nocompression');
fprintf('DANT done! Output is saved to %s!\n', fullfile(user_settings.output_folder, 'Output.mat'));
fprintf('Found %d clusters and %d matches from %d units during %d sessions!\n',...
    Output.NumClusters, size(Output.MatchedPairs, 1), Output.NumUnits, Output.NumSession);

end