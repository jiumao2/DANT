function Motion = computeMotion(user_settings, similarity_matrix, hdbscan_matrix, idx_unit_pairs, similarity_thres, sessions, locations)
% COMPUTEMOTION  Estimate session‐to‐session probe drift from matched unit pairs.
%
% Estimates depth motion across recording sessions by fitting depth‐correction
% parameters to reliable unit matches and computing confidence intervals.
% 1. Selects unit pairs exceeding a similarity threshold and sharing cluster membership.
% 2. Computes raw depth differences (dy) and mean depths for each good pair.
% 3. Fits either a linear‐correction model or default offset model via optimization.
% 4. Uses bootstrapping to derive 95% confidence intervals for session‐wise motion.
% 5. Generates diagnostic plots for similarity threshold and estimated drift.
%
% Inputs:
%   user_settings        struct
%       .waveformCorrection.linear_correction   logical
%           Flag to use linear correction model.
%       .save_intermediate_figures              logical
%           Flag to export diagnostic figures.
%       .save_intermediate_results              logical
%           Flag to save intermediate results to disk.
%       .output_folder                          char or string
%           Directory for saving figures and results.
%
%   similarity_matrix    double matrix (n_unit × n_unit)
%       Pairwise similarity values between all units.
%
%   hdbscan_matrix       logical matrix (n_unit × n_unit)
%       Adjacency matrix of final HDBSCAN clusters.
%
%   idx_unit_pairs       integer matrix (n_pairs × 2)
%       Unit‐pair indices evaluated for motion estimation.
%
%   similarity_thres     double scalar
%       Threshold on similarity to select good pairs.
%
%   sessions             integer vector (n_unit × 1)
%       Session index for each unit (1…n_session).
%
%   locations            double matrix (n_unit × 2)
%       X and Y (depth) coordinates of each unit on the probe.
%
% Outputs:
%   Motion               struct with fields:
%     .Linear            1 × n_session
%       Fitted linear coefficients per session.
%     .Constant          1 × n_session
%       Fitted constant offsets per session.
%     .LinearScale       double scalar
%       Global scaling factor applied to linear terms.
%
% Date:    20250821  
% Author:  Yue Huang 

n_session = max(sessions);
session_pairs = sessions(idx_unit_pairs);
idx_out = sub2ind(size(similarity_matrix), idx_unit_pairs(:,1), idx_unit_pairs(:,2));
good_matrix = (similarity_matrix > similarity_thres) & (hdbscan_matrix == 1);
idx_good = find(good_matrix(idx_out) == 1 & session_pairs(:,1) ~= session_pairs(:,2));

fprintf('%d pairs of units are included for drift estimation!\n', length(idx_good));

linear_scale = 1/1000;

Motion = struct('Linear', zeros(1, n_session), 'Constant', zeros(1, n_session), 'LinearScale', linear_scale);

if isempty(idx_good)
    Motion = struct('Linear', zeros(1, n_session), 'Constant', zeros(1, n_session), 'LinearScale', linear_scale);
    return
end

% get all the good pairs and their distance
session_pairs_good = session_pairs(idx_good,:)';

depth = zeros(1, length(idx_good));
dy = zeros(1, length(idx_good));
for k = 1:length(idx_good)
    unit1 = idx_unit_pairs(idx_good(k), 1);
    unit2 = idx_unit_pairs(idx_good(k), 2);
    depth(k) = mean(locations([unit1, unit2], 2));
    dy(k) = locations(unit2, 2) - locations(unit1, 2);
end

% compute the motion and 95CI
n_boot = 100;

if length(unique(session_pairs_good)) ~= n_session
    disp('Some sessions are not included! Motion estimation failed!');
end

options = optimset('MaxFunEvals', 1e8, 'MaxIter', 1e8);

if user_settings.waveformCorrection.linear_correction
    loss_fun = @(params)lossFunLinearCorrection(params, session_pairs_good, dy, depth, linear_scale, n_session);
    params = fminunc(loss_fun, rand(1, n_session*2-2), options);
    Motion.Linear = [0, params(1:n_session-1)];
    Motion.Constant = [0, params(n_session:end)];

    fprintf('Distortion range: %.2f%% ~ %.2f%% relative to the probe\n',...
        min(Motion.Linear)/range(depth)*100,...
        max(Motion.Linear)/range(depth)*100);

    mean_motion = Motion.LinearScale*Motion.Linear*mean(depth) + Motion.Constant;
    Motion.Constant = Motion.Constant - mean(mean_motion);

    mean_motion = Motion.LinearScale*Motion.Linear*mean(depth) + Motion.Constant;
    min_motion = Motion.LinearScale*Motion.Linear*min(depth) + Motion.Constant;
    max_motion = Motion.LinearScale*Motion.Linear*max(depth) + Motion.Constant;
else
    loss_fun = @(params)lossFunLinearDefault(params, session_pairs_good, dy);
    params = fminunc(loss_fun, rand(1, n_session), options);
    
    Motion.Constant = params - mean(params);

    mean_motion = Motion.Constant;
    min_motion = [];
    max_motion = [];
end

options = optimset('MaxFunEvals', 1e8, 'MaxIter', 1e8, 'Display', 'none');
mean_motion_boot = zeros(n_boot, n_session);
min_motion_boot = zeros(n_boot, n_session);
max_motion_boot = zeros(n_boot, n_session);

% start parallel pool
if ~isfield(user_settings, 'n_jobs') || user_settings.n_jobs ~= 0
    is_parallel = true;
else
    is_parallel = false;
end

if is_parallel && isempty(gcp('nocreate'))
    c = parcluster('local');
    if ~isfield(user_settings, 'n_jobs') || user_settings.n_jobs == -1
        parpool(c.NumWorkers);
    else
        parpool(user_settings.n_jobs);
    end
end

progBar = ProgressBar(n_boot, ...
    'IsParallel', is_parallel, ...
    'Title', 'Computing 95CI', ...
    'UpdateRate', 1 ...
    );
progBar.setup([], [], []);

if is_parallel
    parfor j = 1:n_boot
        idx_rand = randi(length(dy), 1, length(dy));
        dy_this = dy(idx_rand);
        session_pairs_this = session_pairs_good(:, idx_rand);
        depth_this = depth(idx_rand);
    
        if user_settings.waveformCorrection.linear_correction
            loss_fun = @(params)lossFunLinearCorrection(params, session_pairs_this, dy_this, depth_this, linear_scale, n_session);
            params = fminunc(loss_fun, rand(1, n_session*2-2), options);
            p_linear = [0, params(1:n_session-1)];
            p_constant = [0, params(n_session:end)];
    
            mean_motion_this = linear_scale*p_linear*mean(depth_this) + p_constant;
            p_constant = p_constant - mean(mean_motion_this);
        
            mean_motion_boot(j,:) = linear_scale*p_linear*mean(depth_this) + p_constant;
            min_motion_boot(j,:) = linear_scale*p_linear*min(depth_this) + p_constant;
            max_motion_boot(j,:) = linear_scale*p_linear*max(depth_this) + p_constant;
        else
            loss_fun = @(params)lossFunLinearDefault(params, session_pairs_this, dy_this);
            params = fminunc(loss_fun, rand(1, n_session), options);
            mean_motion_boot(j,:) = params - mean(params);
        end
    
        updateParallel(1);
    end
else
    for j = 1:n_boot
        idx_rand = randi(length(dy), 1, length(dy));
        dy_this = dy(idx_rand);
        session_pairs_this = session_pairs_good(:, idx_rand);
        depth_this = depth(idx_rand);
    
        if user_settings.waveformCorrection.linear_correction
            loss_fun = @(params)lossFunLinearCorrection(params, session_pairs_this, dy_this, depth_this, linear_scale, n_session);
            params = fminunc(loss_fun, rand(1, n_session*2-2), options);
            p_linear = [0, params(1:n_session-1)];
            p_constant = [0, params(n_session:end)];
    
            mean_motion_this = linear_scale*p_linear*mean(depth_this) + p_constant;
            p_constant = p_constant - mean(mean_motion_this);
        
            mean_motion_boot(j,:) = linear_scale*p_linear*mean(depth_this) + p_constant;
            min_motion_boot(j,:) = linear_scale*p_linear*min(depth_this) + p_constant;
            max_motion_boot(j,:) = linear_scale*p_linear*max(depth_this) + p_constant;
        else
            loss_fun = @(params)lossFunLinearDefault(params, session_pairs_this, dy_this);
            params = fminunc(loss_fun, rand(1, n_session), options);
            mean_motion_boot(j,:) = params - mean(params);
        end
    
        progBar([], [], []);
    end    
end
progBar.release();

mean_motion_ci95 = zeros(2, n_session);
min_motion_ci95 = zeros(2, n_session);
max_motion_ci95 = zeros(2, n_session);
for j = 1:n_session
    mean_motion_ci95(1,j) = prctile(mean_motion_boot(:,j), 2.5);
    mean_motion_ci95(2,j) = prctile(mean_motion_boot(:,j), 97.5);

    min_motion_ci95(1,j) = prctile(min_motion_boot(:,j), 2.5);
    min_motion_ci95(2,j) = prctile(min_motion_boot(:,j), 97.5);

    max_motion_ci95(1,j) = prctile(max_motion_boot(:,j), 2.5);
    max_motion_ci95(2,j) = prctile(max_motion_boot(:,j), 97.5);
end    

% plot the final similarity score distribution
similarity = similarity_matrix(idx_out);

fig = EasyPlot.figure();
ax_similarity = EasyPlot.axes(fig,...
    'Width', 3,...
    'Height', 3,...
    'MarginBottom', 1,...
    'MarginLeft', 1);

xline(ax_similarity, similarity_thres, 'k:', 'LineWidth', 2);

xlabel(ax_similarity, 'Waveform similarity');
ylabel(ax_similarity, 'Prob.');

histogram(ax_similarity, similarity, 'BinWidth', 0.2, 'Normalization', 'probability');
title(ax_similarity, [num2str(length(idx_good)), ' pairs are included']);
EasyPlot.cropFigure(fig);
drawnow;

if user_settings.save_intermediate_figures
    EasyPlot.exportFigure(fig, fullfile(user_settings.output_folder, 'Figures/SimilarityThresholdForCorrection'), 'dpi', 300);
end

% Plot the drift
% compute the residues
location_estimated = depth*Motion.LinearScale.*Motion.Linear(session_pairs_good) + Motion.Constant(session_pairs_good);
dy_estimated = location_estimated(2,:) - location_estimated(1,:);

dy_left = dy - dy_estimated;

%% Make the plot
fig = EasyPlot.figure();
ax_drift = EasyPlot.axes(fig, 'Height', 3, 'Width', 5,...
    'MarginBottom', 1,...
    'MarginLeft', 1,...
    'MarginRight', 4);

ax_distance = EasyPlot.createAxesAgainstAxes(fig, ax_drift, 'right',...
    'Width', 8);

colors = [0.7,0.7,0.7; lines(1)];

% drift
h1 = plot(ax_drift, 1:n_session, mean_motion, '-', 'Color', 'k');
EasyPlot.plotShaded(ax_drift, 1:n_session, mean_motion_ci95, 'shadedColor', 'k');

if user_settings.waveformCorrection.linear_correction
    h2 = plot(ax_drift, 1:n_session, min_motion, '-', 'Color', 'b');
    EasyPlot.plotShaded(ax_drift, 1:n_session, min_motion_ci95, 'shadedColor', 'b');
    h3 = plot(ax_drift, 1:n_session, max_motion, '-', 'Color', 'r');
    EasyPlot.plotShaded(ax_drift, 1:n_session, max_motion_ci95, 'shadedColor', 'r');

    h_legend = EasyPlot.legend(ax_drift, {'Mean motion', 'Bottom motion', 'Top motion'},...
        'location', 'northeastoutside',...
        'selectedPlots', [h1,h2,h3],...
        'lineLength', 0.5);
    EasyPlot.move(h_legend, 'dx', -1);
end

xlabel(ax_drift, 'Session');
ylabel(ax_drift, 'Motion (μm)');

% raw distance
plot(ax_distance, depth, dy, '.', 'Color', colors(1,:));
plot(ax_distance, depth, dy_left, '.', 'Color', colors(2,:));

xlabel(ax_distance, 'Depth (μm)');
ylabel(ax_distance, 'Residues (μm)');

xlim(ax_distance, [min(depth), max(depth)]);
ylim(ax_distance, [min(dy), max(dy)]);

EasyPlot.cropFigure(fig);
drawnow;
if user_settings.save_intermediate_figures
    EasyPlot.exportFigure(fig, fullfile(user_settings.output_folder, 'Figures/Motion'));
end

% save data
if user_settings.save_intermediate_results
    save(fullfile(user_settings.output_folder, 'Motion.mat'), 'Motion', '-nocompression');
end

end