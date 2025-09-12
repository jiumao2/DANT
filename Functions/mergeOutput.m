function Output = mergeOutput(user_settings, spikeInfo, shanks_data, output_folder)
% MERGEOUTPUT  Combine per‐shank clustering and waveform outputs into one.
%
% This function loads the individual shank results saved under
% output_folder/Shank<ID>/Output.mat and Waveforms.mat, then concatenates
% cluster assignments, similarity data, curation logs, motion parameters,
% and corrected waveforms into a single unified Output struct.  The
% combined Output and waveforms_corrected array are saved back to disk.
%
% Inputs:
%   user_settings            struct
%       .waveformCorrection.n_templates   integer
%           Number of templates per unit for waveform correction.
%
%   spikeInfo                struct array (1×Nunits)
%       Preprocessed spike data for each unit, with at least:
%           .SessionIndex       integer scalar
%           .Waveform           nChannel×nSample matrix
%
%   shanks_data              integer vector (1×Nunits)
%       Shank ID assignment (e.g., [1 1 2 2 3 3 …]) for each spikeInfo unit.
%
%   output_folder            char or string
%       Root directory containing subfolders 'Shank<ID>' with saved results.
%
% Outputs:
%   Output                   struct with fields:
%       .IdxUnit             1×Nunits  Original unit indices.
%       .IdxShank            1×Nunits  Shank assignment per unit.
%       .NumClusters         integer   Total clusters across all shanks.
%       .NumUnits            integer   Total number of units.
%       .Locations           Nunits×3   [X,Y,Z] coordinates for each unit.
%       .IdxSort             1×Nunits  Global sort order for plotting.
%       .IdxCluster          Nunits×1   Cluster IDs (–1 for unmatched).
%       .SimilarityMatrix    Nunits×Nunits  Global similarity matrix.
%       .SimilarityAll       Npairs×nMetrics  Concatenated feature matrix.
%       .SimilarityPairs     Npairs×2  Global list of unit‐pairs.
%       .SimilarityNames     cell(1×nMetrics)  Feature names.
%       .SimilarityWeights   vector    Per‐shank weights concatenated.
%       .SimilarityThreshold vector    Per‐shank thresholds concatenated.
%       .GoodMatchesMatrix   Nunits×Nunits  Binary match indicator.
%       .ClusterMatrix       Nunits×Nunits  Cluster‐membership indicator.
%       .MatchedPairs        M×2       List of all matched pairs.
%       .CurationPairs       K×2       List of pairs flagged for curation.
%       .CurationTypes       1×K       Curation action codes per pair.
%       .CurationTypeNames   cell      Labels for curation action codes.
%       .CurationNumRemoval  integer   Total units removed during curation.
%       .Params              struct    Copy of user_settings.
%       .NumSession          integer   Number of recording sessions.
%       .Sessions            1×Nunits  Session index per unit.
%       .SessionNames        1×Nunits  Session name per unit.
%       .Motion              struct(1×nShanks)  Motion correction params.
%       .RunTime             numeric   Runtime (sec) of last shank merge.
%       .DateTime            char      Timestamp of merge call.
%
% Date:    20250821
% Author:  Yue Huang

n_session = max([spikeInfo.SessionIndex]);
shankIDs = unique(shanks_data);

% Create an empty Output
Output = struct(...
    'IdxUnit', 1:length(spikeInfo),...
    'IdxShank', shanks_data,...
    'NumClusters', 0,...
    'NumUnits', length(spikeInfo),...
    'Locations', zeros(length(spikeInfo), 3),...
    'IdxSort', zeros(1, length(spikeInfo)),...
    'IdxCluster', zeros(length(spikeInfo), 1),...
    'SimilarityMatrix', zeros(length(spikeInfo)),...
    'SimilarityAll', [],...
    'SimilarityPairs', [],...
    'SimilarityNames', {user_settings.clustering.features'},...
    'SimilarityWeights', [],...
    'SimilarityThreshold', [],...
    'GoodMatchesMatrix', zeros(length(spikeInfo)),...
    'ClusterMatrix', zeros(length(spikeInfo)),...
    'MatchedPairs', [],...
    'CurationPairs', [],...
    'CurationTypes', [],...
    'CurationTypeNames', [],...
    'CurationNumRemoval', 0,...
    'Params', user_settings,...
    'NumSession', n_session,...
    'Sessions', zeros(1, length(spikeInfo)),...
    'SessionNames', [],...
    'Motion', struct('Linear', [], 'Constant', [], 'LinearScale', []),...
    'RunTime', [],...
    'DateTime', []);
Output.SessionNames = cell(1, length(spikeInfo));

waveforms_corrected = zeros(length(spikeInfo), size(spikeInfo(1).Waveform, 1), size(spikeInfo(1).Waveform, 2), user_settings.waveformCorrection.n_templates);

n_cluster = 0;
n_units = 0;
for i_shank = 1:length(shankIDs)
    shankID = shankIDs(i_shank);

    fprintf('Loading Output from shank %d ...\n', shankID);
    data = load(fullfile(output_folder, ['Shank', num2str(shankID)], 'Output.mat'));
    data_waveforms = load(fullfile(output_folder, ['Shank', num2str(shankID)], 'Waveforms.mat'));
    idx_units = find(shanks_data == shankID);

    Output.Locations(idx_units, :) = data.Output.Locations;
    Output.IdxSort(n_units+1:n_units+data.Output.NumUnits) = idx_units(data.Output.IdxSort);

    Output.IdxCluster(idx_units) = data.Output.IdxCluster + n_cluster;
    Output.IdxCluster(idx_units(data.Output.IdxCluster == -1)) = -1;
    Output.SimilarityMatrix(idx_units, idx_units) = data.Output.SimilarityMatrix;
    Output.SimilarityAll = [Output.SimilarityAll; data.Output.SimilarityAll];

    similarity_pairs = arrayfun(@(x)idx_units(x), data.Output.SimilarityPairs);
    Output.SimilarityPairs = [Output.SimilarityPairs; similarity_pairs];

    Output.SimilarityWeights = [Output.SimilarityWeights; data.Output.SimilarityWeights];
    Output.SimilarityThreshold = [Output.SimilarityThreshold; data.Output.SimilarityThreshold];
    Output.GoodMatchesMatrix(idx_units, idx_units) = data.Output.GoodMatchesMatrix;
    Output.ClusterMatrix(idx_units, idx_units) = data.Output.ClusterMatrix;

    matched_pairs = arrayfun(@(x)idx_units(x), data.Output.MatchedPairs);
    Output.MatchedPairs = [Output.MatchedPairs; matched_pairs];

    curation_pairs = arrayfun(@(x)idx_units(x), data.Output.CurationPairs);
    Output.CurationPairs = [Output.CurationPairs; curation_pairs];
    Output.CurationTypes = [Output.CurationTypes, data.Output.CurationTypes];
    Output.CurationTypeNames = data.Output.CurationTypeNames;
    Output.CurationNumRemoval = Output.CurationNumRemoval + data.Output.CurationNumRemoval;

    Output.Sessions(idx_units) = data.Output.Sessions;
    if isfield(data.Output, 'SessionNames')
        Output.SessionNames(idx_units) = data.Output.SessionNames;
    end
    Output.Motion(i_shank) = data.Output.Motion;

    Output.RunTime = data.Output.RunTime; % save the run time of the final shank
    Output.DateTime = datestr(datetime('now'));
    
    % update waveforms
    waveforms_corrected(idx_units,:,:,:) = data_waveforms.waveforms_corrected;

    n_cluster = n_cluster + data.Output.NumClusters;
    n_units = n_units + data.Output.NumUnits;
end

Output.NumClusters = n_cluster;

% Save the combined output
fprintf('Saving Output to %s ...\n', fullfile(output_folder, 'Output.mat'));
save(fullfile(output_folder, 'Output.mat'), 'Output', '-nocompression');
save(fullfile(output_folder, 'Waveforms.mat'), 'waveforms_corrected', '-nocompression');

end