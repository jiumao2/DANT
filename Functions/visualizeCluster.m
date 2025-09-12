function visualizeCluster(Output, cluster_id, spikeInfo, waveforms, user_settings)
% VISUALIZECLUSTER  Visualize properties of a single cluster across sessions and features.
%
% This function generates a multi‐panel figure for the specified cluster that includes:
%   (1) probe depth versus session index,
%   (2) overlapped waveforms arranged by channel positions,
%   (3) feature traces for ISI, autocorrelation, and PETH,
%   (4) two‐dimensional scatter and similarity matrices for unit pairs.
%
% Inputs:
%   Output                struct  
%       IdxCluster         integer (n_units × 1)       cluster label for each unit
%       Sessions           integer (n_units × 1)       session index for each unit
%       Motion             struct with fields "LinearScale", "Linear" and "Constant"
%       Locations          double (n_units × 2)        [x,y] coordinates of each unit peak
%       SimilarityPairs    integer (P × 2)             unit index pairs for similarity data
%       SimilarityAll      double (P × M)              similarity values for each pair and feature
%       SimilarityNames    cell (1 × M) of char        names of similarity features
%       SimilarityWeights  double (M × 1)              weights for each similarity feature
%       SimilarityMatrix   double (n_units × n_units)  combined or weighted similarity matrix
%
%   cluster_id            integer scalar               cluster label to visualize
%
%   spikeInfo             struct array (n_units × 1)
%       ISI               double vector                inter‐spike interval features
%       AutoCorr          double matrix                autocorrelation features
%       PETH              double matrix                peristimulus time histogram features
%       Xcoords, Ycoords  double (n_channels × 1)      channel coordinates for waveform layout
%
%   waveforms             double (n_units × n_channels × n_samples × n_templates)
%       waveform snippets for each unit across channels, time samples, and correction templates
%
%   user_settings         struct
%       clustering.max_distance double scalar          maximum spatial distance for waveform alignment
%       .output_folder               char or string specifying the directory for saved figures  
%
% Outputs:
%   This function does not return variables. It creates and displays a figure summarizing
%   cluster‐specific depth, waveform, feature, and similarity information.
%   The figure will be saved to disk.
%
% Date:    20250821  
% Author:  Yue Huang

units = find(Output.IdxCluster == cluster_id);
sessions = Output.Sessions(units);
[~, idx_sort] = sort(sessions);
units = units(idx_sort);
sessions = sessions(idx_sort);

probe_positions = Output.Motion.LinearScale*Output.Motion.Linear(sessions).*Output.Locations(units, 2)' + Output.Motion.Constant(sessions);
locations = Output.Locations(units, 1:2) - probe_positions';
colors = winter(length(units));

waveforms = waveforms(units,:,:,1);

ISI = [];
if isfield(spikeInfo, 'ISI')
    ISI = cat(1, spikeInfo(units).ISI);
end

AutoCorr = [];
if isfield(spikeInfo, 'AutoCorr')
    AutoCorr = cat(1, spikeInfo(units).AutoCorr);
    AutoCorr(:, (size(AutoCorr, 2)+1)/2) = NaN;
end

PETH = [];
if isfield(spikeInfo, 'PETH')
    PETH = cat(1, spikeInfo(units).PETH);
end

fig = EasyPlot.figure();

% depth
ax_depth = EasyPlot.axes(fig,...
    'Width', 5,...
    'Height', 3,...
    'MarginBottom', 1,...
    'MarginLeft', 1);

plot(ax_depth, sessions, locations(:,2), 'k-');
for k = 1:length(sessions)
    plot(ax_depth, sessions(k), locations(k,2), '.', 'Color', colors(k,:),...
        'MarkerSize', 20);
end

title(ax_depth, ['n = ', num2str(length(units))]);
xlim(ax_depth, [min(sessions)-0.5, max(sessions)+0.5]);
ylim(ax_depth,...
    [min(mean(locations(:,2)) - user_settings.clustering.max_distance/2, min(locations(:,2) - 5)),...
    max(mean(locations(:,2)) + user_settings.clustering.max_distance/2, max(locations(:,2) + 5))]);
xlabel(ax_depth, 'Sessions');
ylabel(ax_depth, 'Depth (um)');

% waveforms
ptt = max(waveforms,[],3) - min(waveforms,[],3);
[~, peak_channels] = max(ptt, [], 2);
ch = mode(peak_channels);
amplitude = max(ptt(:));

n_channels = 20;
channel_locations = [spikeInfo(1).Xcoords, spikeInfo(1).Ycoords];
distance_to_location = sqrt(sum((channel_locations - channel_locations(ch,:)).^2, 2));
[~, idx_sort] = sort(distance_to_location);
ch_included = idx_sort(1:n_channels);
waveforms_plot = waveforms(:,ch_included,:);


x_plot = cell(1, length(units));
y_plot = cell(1, length(units));

samples_plot = (1:size(waveforms_plot, 3)) - (size(waveforms_plot, 3)+1)/2;
sample_scale = 1;
x_scale = 3;
y_scale = 1; % based on the amplitude
waveform_scale = 1./amplitude*50;
for j = 1:length(units)
    for k = 1:n_channels
        x = channel_locations(ch_included(k), 1);
        y = channel_locations(ch_included(k), 2);
    
        x_plot{j} = [x_plot{j}, x*x_scale+samples_plot*sample_scale, NaN];
        y_plot{j} = [y_plot{j}, y*y_scale+squeeze(waveforms_plot(j,k,:))' * waveform_scale, NaN];
    end
end

ax_waveform = EasyPlot.createAxesAgainstAxes(fig, ax_depth, 'bottom',...
    'Height', 8,...
    'YAxisVisible', 'off',...
    'XAxisVisible', 'off');

for k = 1:length(units)
    plot(ax_waveform, x_plot{k}, y_plot{k}, '-', 'Color', colors(k,:));
end 

EasyPlot.setYLim(ax_waveform, [min(y_plot{1}) - 10, max(y_plot{1}) + 10]);
EasyPlot.setXLim(ax_waveform, [min(x_plot{1}) - 10, max(x_plot{1}) + 10]);

h_scalebar = EasyPlot.scalebar(ax_waveform, 'XY',...
    'location', 'southeast',...
    'xBarLabel', '1 ms',...
    'xBarRatio', 1,...
    'xBarLength', 30,...
    'yBarLabel', '0.2 mV',...
    'yBarRatio', waveform_scale,...
    'yBarLength', 100);

EasyPlot.move(h_scalebar, 'dx', 1);

% similarity
overlaps = {...
    [],...
    squeeze(waveforms_plot(:,1,:)),...
    ISI,...
    AutoCorr,...
    PETH};

WaveformSimilarityMatrix = NaN(length(units));
ISI_SimilarityMatrix = NaN(length(units));
AutoCorrSimilarityMatrix = NaN(length(units));
PETH_SimilarityMatrix = NaN(length(units));

for k = 1:size(Output.SimilarityPairs, 1)
    if ~any(units == Output.SimilarityPairs(k,1)) || ~any(units == Output.SimilarityPairs(k,2))
        continue
    end
    
    idx1 = find(units == Output.SimilarityPairs(k,1));
    idx2 = find(units == Output.SimilarityPairs(k,2));

    for j = 1:length(Output.SimilarityNames)
        if strcmpi(Output.SimilarityNames{j}, 'waveform')
            WaveformSimilarityMatrix(idx1,idx2) = Output.SimilarityAll(k,j);
            WaveformSimilarityMatrix(idx2,idx1) = Output.SimilarityAll(k,j);
        elseif strcmpi(Output.SimilarityNames{j}, 'ISI')
            ISI_SimilarityMatrix(idx1,idx2) = Output.SimilarityAll(k,j);
            ISI_SimilarityMatrix(idx2,idx1) = Output.SimilarityAll(k,j);
        elseif strcmpi(Output.SimilarityNames{j}, 'AutoCorr')
            AutoCorrSimilarityMatrix(idx1,idx2) = Output.SimilarityAll(k,j);
            AutoCorrSimilarityMatrix(idx2,idx1) = Output.SimilarityAll(k,j);
        elseif strcmpi(Output.SimilarityNames{j}, 'PETH')
            PETH_SimilarityMatrix(idx1,idx2) = Output.SimilarityAll(k,j);
            PETH_SimilarityMatrix(idx2,idx1) = Output.SimilarityAll(k,j);
        end
    end
end

similarity_matrix = {...
    Output.SimilarityMatrix(units, units),...
    WaveformSimilarityMatrix,...
    ISI_SimilarityMatrix,...
    AutoCorrSimilarityMatrix,...
    PETH_SimilarityMatrix,...
    };

names_all = {'Waveform', 'ISI', 'AutoCorr', 'PETH'};
idx_names = zeros(1, length(Output.SimilarityNames));
for k = 1:length(Output.SimilarityNames)
    idx_names(k) = find(strcmpi(names_all, Output.SimilarityNames{k}));
end
overlaps = overlaps([1, idx_names+1]);
similarity_matrix = similarity_matrix([1, idx_names+1]);

similarity_names = ['Weighted sum', Output.SimilarityNames];

ax_similarity = EasyPlot.createGridAxes(fig, 2, length(similarity_names),...
    'Width', 3,...
    'Height', 3,...
    'MarginLeft', 1,...
    'MarginBottom', 1);

EasyPlot.place(ax_similarity, ax_depth, 'right');
EasyPlot.align(ax_similarity, ax_depth, 'top');


EasyPlot.set(ax_similarity(2,:),...
    'Color', [0.7,0.7,0.7]);

for k = 1:length(ax_similarity)
    similarity_matrix{k}(eye(size(similarity_matrix{k})) == 1) = NaN;
    
    for j = 1:size(overlaps{k}, 1)
        if k > 1
            plot(ax_similarity{1,k}, 1:size(overlaps{k},2), overlaps{k}(j,:), '-', 'Color', colors(j,:));
        end
    end

    imagesc(ax_similarity{2,k}, similarity_matrix{k}, 'AlphaData', ~isnan(similarity_matrix{k}));
    title(ax_similarity{1,k}, similarity_names{k});

    if k == 1
        title(ax_similarity{2,k}, similarity_names{k});
    else
        title(ax_similarity{2,k}, ['weight = ', num2str(Output.SimilarityWeights(k-1), '%.3f')]);
    end
end

EasyPlot.setXLim(ax_similarity(2,:), [0.5, length(units)+0.5]);
EasyPlot.setYLim(ax_similarity(2,:), [0.5, length(units)+0.5]);
EasyPlot.setCLim(ax_similarity(2,:), [0, 4]);
EasyPlot.colorbar(ax_similarity{2,end}, 'label', 'Similarity', 'MarginRight', 1);

EasyPlot.xticklabels(ax_similarity(2,:), '');
EasyPlot.yticklabels(ax_similarity(2,:), '');
xlabel(ax_similarity{2,1}, 'Units (sorted by sessions)');

% 2D scatter
similarity_all = Output.SimilarityAll;
similarity_names = Output.SimilarityNames;
similarity_matched = cell(1, length(similarity_names));
similarity_unmatched = cell(1, length(similarity_names));
similarity_this = cell(1, length(similarity_names));

is_matched = arrayfun(@(x)Output.ClusterMatrix(Output.SimilarityPairs(x,1), Output.SimilarityPairs(x,2)), 1:size(similarity_all,1));
idx_matched = find(is_matched == 1);
idx_unmatched = find(is_matched == 0);

temp_matrix = zeros(Output.NumUnits);
temp_matrix(units, units) = 1;
is_this_cluster = arrayfun(@(x)temp_matrix(Output.SimilarityPairs(x,1), Output.SimilarityPairs(x,2)), 1:size(similarity_all,1));
idx_this_cluster = find(is_this_cluster == 1);

similarity = sum(Output.SimilarityAll.*Output.SimilarityWeights, 2);
histogram(ax_similarity{1,1}, similarity(idx_unmatched), 'FaceColor', 'k', 'BinWidth', 0.1, 'Normalization', 'probability');
histogram(ax_similarity{1,1}, similarity(idx_matched), 'FaceColor', 'b', 'BinWidth', 0.1, 'Normalization', 'probability');
xline(ax_similarity{1,1}, Output.SimilarityThreshold, 'k:', 'lineWidth', 2);
plot(ax_similarity{1,1}, similarity(idx_this_cluster), zeros(length(idx_this_cluster), 1), 'g.', 'MarkerSize', 3);

for k = 1:length(similarity_names)
    similarity_matched{k} = similarity_all(idx_matched,k);
    similarity_unmatched{k} = similarity_all(idx_unmatched,k);
    similarity_this{k} = similarity_all(idx_this_cluster,k);
end

idx_scatter = cell(1, length(similarity_names) - 1);
for k = 1:length(idx_scatter)
    idx_scatter{k} = [1, k+1];
end

ax_scatter = EasyPlot.createGridAxes(fig, 1, max(1, length(idx_scatter)),...
    'Width', 4,...
    'Height', 4,...
    'MarginLeft', 1,...
    'MarginRight', 1,...
    'MarginBottom', 1);

EasyPlot.align(ax_scatter, ax_similarity, 'horizontalCenter');
EasyPlot.align(ax_scatter, ax_waveform, 'bottom');

max_points = 5000;
for k = 1:length(idx_scatter)
    if length(similarity_unmatched{idx_scatter{k}(1)}) > max_points
        idx_plot = randperm(length(similarity_unmatched{idx_scatter{k}(1)}), max_points);
    else
        idx_plot = 1:length(similarity_unmatched{idx_scatter{k}(1)});
    end

    plot(ax_scatter{k},...
        similarity_unmatched{idx_scatter{k}(1)}(idx_plot),...
        similarity_unmatched{idx_scatter{k}(2)}(idx_plot), 'k.',...
        'MarkerSize', 1);

    if length(similarity_matched{idx_scatter{k}(1)}) > max_points
        idx_plot = randperm(length(similarity_matched{idx_scatter{k}(1)}), max_points);
    else
        idx_plot = 1:length(similarity_matched{idx_scatter{k}(1)});
    end

    plot(ax_scatter{k},...
        similarity_matched{idx_scatter{k}(1)}(idx_plot),...
        similarity_matched{idx_scatter{k}(2)}(idx_plot), 'b.',...
        'MarkerSize', 1);

    plot(ax_scatter{k},...
        similarity_this{idx_scatter{k}(1)},...
        similarity_this{idx_scatter{k}(2)}, 'g+',...
        'MarkerSize', 5);

    xlabel(ax_scatter{k}, similarity_names{idx_scatter{k}(1)});
    ylabel(ax_scatter{k}, similarity_names{idx_scatter{k}(2)});
end

EasyPlot.legend(ax_scatter{end}, {'UnMatched', 'Matched', 'This cluster'},...
    'location', 'northeastoutside');

h = EasyPlot.setGeneralTitle([{ax_depth}, ax_similarity(1,:)], ['Cluster #', num2str(cluster_id)],...
    'fontSize', 15);
EasyPlot.move(h, 'dy', 1);

EasyPlot.cropFigure(fig);

if ~exist(fullfile(user_settings.output_folder, 'Figures/Clusters/'), 'dir')
    mkdir(fullfile(user_settings.output_folder, 'Figures/Clusters/'));
end
EasyPlot.exportFigure(fig, fullfile(user_settings.output_folder, 'Figures/Clusters', ['Cluster', num2str(cluster_id)]), 'dpi', 300);

end