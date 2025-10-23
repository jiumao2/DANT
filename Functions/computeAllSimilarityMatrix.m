function [similarity_matrix_all, feature_names_all] = computeAllSimilarityMatrix( ...
    user_settings, waveforms_all, channel_locations, ISI_features, AutoCorr_features, PETH_features, feature_names, idx_unit_pairs)
% COMPUTEALLSIMILARITYMATRIX  Compute and visualize similarity matrices across multiple features.
%
% This function computes pairwise similarity matrices for waveform, ISI, autocorrelation, 
% and PETH features as specified by feature_names. The resulting matrices are concatenated 
% into a 3D array. A histogram of similarity values for each requested unit pair is plotted, 
% and figures are optionally saved to disk.
%
% Inputs:
%   user_settings               struct  
%       .save_intermediate_figures   logical scalar indicating whether to export figures  
%       .output_folder               char or string specifying the directory for saved figures  
%
%   waveforms_all               double array (n_unit × C × T)  
%       Waveforms for all units: C channels over T time points  
%
%   channel_locations           double array (C × 2) or (C × 3)  
%       Spatial coordinates of each recording channel  
%
%   ISI_features                double matrix (n_unit x F_ISI)  
%       Inter-spike interval features for each of n_unit units  
%
%   AutoCorr_features           double matrix (n_unit x F_AC)  
%       Autocorrelation features for each of n_unit units  
%
%   PETH_features               double matrix (n_unit x F_PETH)  
%       Peristimulus time histogram features for each of n_unit units  
%
%   feature_names               cell (1 × K) of char  
%       Subset of {'Waveform','ISI','AutoCorr','PETH'} indicating which similarities to compute  
%
%   idx_unit_pairs              integer matrix (P × 2)  
%       Each row contains a pair of unit indices for which to plot similarity histograms  
%
% Outputs:
%   similarity_matrix_all       double array (n_unit × n_unit × M)  
%       Stack of M similarity matrices, one per feature in feature_names_all  
%
%   feature_names_all           cell (1 × M) of char  
%       Names of all features corresponding to the third‐dimension slices of similarity_matrix_all  
%
% Date:    20250821  
% Author:  Yue Huang

n_unit = size(waveforms_all, 1);
max_similarity = 6; % r = 0.999987

waveform_similarity_matrix = zeros(n_unit);
if any(strcmpi(feature_names, 'Waveform'))
    waveform_similarity_matrix = computeWaveformSimilarityMatrix(user_settings, waveforms_all, channel_locations);
end
waveform_similarity_matrix(waveform_similarity_matrix > max_similarity) = max_similarity;

% compute other similarity
ISI_similarity_matrix = zeros(n_unit);
if any(strcmpi(feature_names, 'ISI'))
    ISI_similarity_matrix = corrcoef(ISI_features');
    ISI_similarity_matrix(isnan(ISI_similarity_matrix)) = 0;
    ISI_similarity_matrix = atanh(ISI_similarity_matrix);
end
ISI_similarity_matrix(ISI_similarity_matrix > max_similarity) = max_similarity;

AutoCorr_similarity_matrix = zeros(n_unit);
if any(strcmpi(feature_names, 'AutoCorr'))
    AutoCorr_similarity_matrix = corrcoef(AutoCorr_features');
    AutoCorr_similarity_matrix(isnan(AutoCorr_similarity_matrix)) = 0;
    AutoCorr_similarity_matrix = atanh(AutoCorr_similarity_matrix);
end
AutoCorr_similarity_matrix(AutoCorr_similarity_matrix > max_similarity) = max_similarity;

PETH_similarity_matrix = zeros(n_unit);
if any(strcmpi(feature_names, 'PETH'))
    PETH_similarity_matrix = corrcoef(PETH_features');
    PETH_similarity_matrix(isnan(PETH_similarity_matrix)) = 0;
    PETH_similarity_matrix = atanh(PETH_similarity_matrix);
end
PETH_similarity_matrix(PETH_similarity_matrix > max_similarity) = max_similarity;

feature_names_all = {'Waveform', 'ISI', 'AutoCorr', 'PETH'};
similarity_matrix_all = cat(3,...
    waveform_similarity_matrix,...
    ISI_similarity_matrix,...
    AutoCorr_similarity_matrix,...
    PETH_similarity_matrix);

% plot the distribution of similarity
fig = EasyPlot.figure();
ax_all = EasyPlot.createGridAxes(fig, 1, length(feature_names),...
    'Width', 5,...
    'Height', 5,...
    'MarginBottom', 1,...
    'MarginLeft', 1);

idx_pairs_in_matrix = sub2ind([n_unit, n_unit], idx_unit_pairs(:,1), idx_unit_pairs(:,2));

for k = 1:length(ax_all)
    idx_this = strcmpi(feature_names_all, feature_names{k});

    similarity_matrix_this = similarity_matrix_all(:, :, idx_this);
    histogram(ax_all{k}, similarity_matrix_this(idx_pairs_in_matrix), 'BinWidth', 0.2, 'Normalization', 'probability');
    xlabel(ax_all{k}, [feature_names{k}, ' similarity']);
    ylabel(ax_all{k}, 'Prob.');    
end

EasyPlot.setYLim(ax_all);
EasyPlot.cropFigure(fig);
drawnow;

if user_settings.save_intermediate_figures
    EasyPlot.exportFigure(fig, fullfile(user_settings.output_folder, 'Figures/AllSimilarity'));
end

end
