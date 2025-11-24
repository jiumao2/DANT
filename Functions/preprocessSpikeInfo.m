function spikeInfo = preprocessSpikeInfo(user_settings, spikeInfo)
% PREPROCESSSPIKEINFO  Prepare directories, validate and preprocess spikeInfo structures.
%
% This function creates output and figure folders, checks session index continuity,
% computes 3D unit locations and amplitudes via spikeLocation, identifies peak channels,
% optionally centers waveforms on their trough, extracts autocorrelogram and ISI features,
% and saves intermediate spikeInfo to disk when requested.
%
% Inputs:
%   user_settings               struct
%       .output_folder               char or string
%           Path for saving results and figures
%       .spikeLocation.n_nearest_channels  double scalar
%           Number of channels for localization
%       .spikeLocation.location_algorithm  char
%           'center_of_mass' or 'monopolar_triangulation'
%       .centering_waveforms          logical scalar
%           Flag to realign waveforms around trough
%       .motionEstimation.features    cell array of char
%           Features for motion estimation (e.g., {'AutoCorr', 'Waveform'})
%       .clustering.features          cell array of char
%           Features for clustering (e.g., {'AutoCorr', 'Waveform'})
%       .autoCorr.window              double scalar (ms)
%           Half‐width of autocorrelogram window
%       .autoCorr.binwidth            double scalar (ms)
%           Bin size for autocorrelogram
%       .autoCorr.gaussian_sigma      double scalar
%           Gaussian smoothing sigma for autocorrelogram
%       .ISI.window                   double scalar (ms)
%           Bin limits for ISI histogram
%       .ISI.binwidth                 double scalar (ms)
%           Bin size for ISI histogram
%       .ISI.gaussian_sigma           double scalar
%           Gaussian smoothing sigma for ISI histogram
%       .save_intermediate_results    logical scalar
%           Flag to save spikeInfo.mat after preprocessing
%
%   spikeInfo                   struct array (1 × n_unit)
%       .SessionIndex             double scalar
%           Session ID starting at 1 and continuous
%       .Waveform                  double (n_channel × n_sample)
%           Raw waveform snippets per unit
%       .SpikeTimes                double vector
%           Sorted spike times in ms
%       .Xcoords, .Ycoords         double vectors (n_channel × 1)
%           Channel probe coordinates
%
% Outputs:
%   spikeInfo                   struct array (1 × n_unit)
%       .Location                 double (1 × 3)
%           Estimated [x,y,z] spike source coordinates
%       .Amplitude                double scalar
%           Peak‐to‐trough amplitude at the max channel
%       .Channel                  double scalar
%           Index of the channel with largest peak‐to‐trough
%       .Waveform                 double (n_channel × n_sample)
%           Centered waveform if centering_waveforms=true
%       .AutoCorr                 double vector (1 × (2*window+1))
%           Normalized autocorrelogram (optional)
%       .ISI                      double vector (1 × window)
%           Smoothed ISI distribution (optional)
%
% Date:    20250821
% Author:  Yue Huang

% make a folder to store the data
if ~exist(fullfile(user_settings.output_folder), 'dir')
    mkdir(fullfile(user_settings.output_folder));
end
fprintf('The output will be saved to %s!\n', user_settings.output_folder);

% make a folder to store the figures
if ~exist(fullfile(user_settings.output_folder, 'Figures'), 'dir')
    mkdir(fullfile(user_settings.output_folder, 'Figures'));
end

% validate the data
n_session = max([spikeInfo.SessionIndex]);
if n_session ~= length(unique([spikeInfo.SessionIndex]))
    error('SessionIndex should start from 1 and be coninuous without any gaps!');
end

% preprocessing data
channel_locations = [spikeInfo(1).Xcoords, spikeInfo(1).Ycoords];

n_unit = length(spikeInfo);
waveforms_all = cat(3, spikeInfo.Waveform);
waveforms_all = permute(waveforms_all, [3,1,2]);


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
disp('Start preprocessing spikeInfo!');

% compute the unit locations
progBar = ProgressBar(n_unit, ...
    'IsParallel', is_parallel, ...
    'Title', 'Compute unit locations', ...
    'UpdateRate', 1 ...
    );
progBar.setup([], [], []);

locations_all = zeros(n_unit, 3);
amp_all = zeros(n_unit, 1);

if is_parallel
    parfor k = 1:n_unit
        [x, y, z, amp] = spikeLocation(squeeze(waveforms_all(k,:,:)), channel_locations,...
            user_settings.spikeLocation.n_nearest_channels,...
            user_settings.spikeLocation.location_algorithm);
    
        locations_all(k,:) = [x,y,z];
        amp_all(k) = amp;
    
        updateParallel(1);
    end
else
    for k = 1:n_unit
        [x, y, z, amp] = spikeLocation(squeeze(waveforms_all(k,:,:)), channel_locations,...
            user_settings.spikeLocation.n_nearest_channels,...
            user_settings.spikeLocation.location_algorithm);
    
        locations_all(k,:) = [x,y,z];
        amp_all(k) = amp;
    
        progBar([], [], []);
    end
end
progBar.release();


% find the peak channels
peak_channels = zeros(1, n_unit);
for k = 1:n_unit
    [~, idx_max] = max(max(squeeze(waveforms_all(k,:,:)), [], 2) - min(squeeze(waveforms_all(k,:,:)), [], 2));
    peak_channels(k) = idx_max;
end


% centering the waveforms (optional)
if user_settings.centering_waveforms
    n_channel = size(waveforms_all, 2);
    n_sample = size(waveforms_all, 3);
    center_position = ceil(n_sample/2);
    waveforms_centered = zeros(n_unit, n_channel, n_sample);

    progBar = ProgressBar(n_unit, ...
        'Title', 'Centering the waveforms', ...
        'UpdateRate', 1);
    
    for k = 1:n_unit
        % get the trough positions
        waveform_peak = squeeze(waveforms_all(k, peak_channels(k), :));
        [~, idx_min] = min(waveform_peak);

        % compute the delay
        delay = center_position - idx_min;
        if delay ~= 0
            fprintf('Correcting unit %d with delay = %d ...\n', k, delay);
        end

        % filling the borders with nearest values
        if delay == 0
            waveforms_centered(k,:,:) = squeeze(waveforms_all(k,:,:));
        elseif delay > 0
            waveforms_centered(k,:,:) = [waveforms_all(k,:,1)'.*ones(n_channel, delay), squeeze(waveforms_all(k,:,1:n_sample-delay))];
        else
            waveforms_centered(k,:,:) = [squeeze(waveforms_all(k,:,-delay+1:end)), waveforms_all(k,:,end)'.*ones(n_channel, -delay)];
        end

        progBar([], [], []);
    end
    progBar.release();

    % save the waveforms to spikeInfo
    for k = 1:n_unit
        spikeInfo(k).Waveform = squeeze(waveforms_centered(k,:,:));
    end
end

% compute spike times related features
spike_times = cell(1, n_unit);
for k = 1:n_unit
    spike_times{k} = sort(spikeInfo(k).SpikeTimes);
end

if any(strcmpi(user_settings.motionEstimation.features, 'AutoCorr')) ||...
            any(strcmpi(user_settings.clustering.features, 'AutoCorr'))
    progBar = ProgressBar(n_unit, ...
        'IsParallel', is_parallel, ...
        'Title', 'Preprocessing AutoCorr', ...
        'UpdateRate', 1 ...
        );
    progBar.setup([], [], []);
    
    window = user_settings.autoCorr.window; % ms   
    binwidth = user_settings.autoCorr.binwidth; % ms   
    sigma = user_settings.autoCorr.gaussian_sigma;
    auto_corr_all = zeros(n_unit, 2*window+1);

    if is_parallel
        parfor k = 1:n_unit
            [auto_corr, lag] = computeAutoCorr(spike_times{k}, window, binwidth);
    
            auto_corr(lag>0) = smoothdata(auto_corr(lag>0), 'gaussian', 5*sigma);
            auto_corr(lag<0) = smoothdata(auto_corr(lag<0), 'gaussian', 5*sigma);
            auto_corr = auto_corr./max(auto_corr);
            
            auto_corr_all(k,:) = auto_corr;
        
            updateParallel(1);
        end
    else
        for k = 1:n_unit
            [auto_corr, lag] = computeAutoCorr(spike_times{k}, window, binwidth);
    
            auto_corr(lag>0) = smoothdata(auto_corr(lag>0), 'gaussian', 5*sigma);
            auto_corr(lag<0) = smoothdata(auto_corr(lag<0), 'gaussian', 5*sigma);
            auto_corr = auto_corr./max(auto_corr);
            
            auto_corr_all(k,:) = auto_corr;
        
            progBar([], [], []);
        end        
    end
    progBar.release();
end

if any(strcmpi(user_settings.motionEstimation.features, 'ISI')) ||...
            any(strcmpi(user_settings.clustering.features, 'ISI'))
    progBar = ProgressBar(n_unit, ...
        'IsParallel', is_parallel, ...
        'Title', 'Preprocessing ISI', ...
        'UpdateRate', 1 ...
        );
    progBar.setup([], [], []);
    
    window = user_settings.ISI.window; % ms   
    sigma = user_settings.ISI.gaussian_sigma;
    binwidth = user_settings.ISI.binwidth;

    isi_all = zeros(n_unit, window);
    if is_parallel
        parfor k = 1:n_unit
            isi = diff(spike_times{k});
            isi_hist = histcounts(isi,...
                'BinLimits', [0, window],...
                'BinWidth', binwidth);
            isi_freq = isi_hist./sum(isi_hist);
            isi_freq_smoothed = smoothdata(isi_freq, 'gaussian', 5*sigma);
            isi_all(k,:) = isi_freq_smoothed;
        
            updateParallel(1);
        end
    else
        for k = 1:n_unit
            isi = diff(spike_times{k});
            isi_hist = histcounts(isi,...
                'BinLimits', [0, window],...
                'BinWidth', binwidth);
            isi_freq = isi_hist./sum(isi_hist);
            isi_freq_smoothed = smoothdata(isi_freq, 'gaussian', 5*sigma);
            isi_all(k,:) = isi_freq_smoothed;
        
            progBar([], [], []);
        end        
    end
    progBar.release();
end

% collect all preprocessed data
for k = 1:n_unit
    % get the location of each unit
    spikeInfo(k).Location = locations_all(k,:);
    spikeInfo(k).Amplitude = amp_all(k);

    % get the peak channels
    spikeInfo(k).Channel = peak_channels(k);

    % get the centered waveforms
    if user_settings.centering_waveforms
        spikeInfo(k).Waveform = squeeze(waveforms_centered(k,:,:));
    end

    % get the autocorrelogram feauture
    if any(strcmpi(user_settings.motionEstimation.features, 'AutoCorr')) ||...
            any(strcmpi(user_settings.clustering.features, 'AutoCorr'))
        spikeInfo(k).AutoCorr = auto_corr_all(k,:);
    end

    % get the ISI feature
    if any(strcmpi(user_settings.motionEstimation.features, 'ISI')) ||...
            any(strcmpi(user_settings.clustering.features, 'ISI'))
        spikeInfo(k).ISI = isi_all(k,:);
    end
end

% save the preprocessed data
if user_settings.save_intermediate_results
    fprintf('Saving to %s...\n', fullfile(user_settings.output_folder, 'spikeInfo.mat'));
    save(fullfile(user_settings.output_folder, 'spikeInfo.mat'), 'spikeInfo', '-nocompression');
end

end






