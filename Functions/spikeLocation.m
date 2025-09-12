function [x, y, z, ptt] = spikeLocation(waveforms_mean, channel_locations, n_nearest_channels, algorithm)
% SPIKELOCATION  Estimate spike source coordinates from channel waveforms.
%
% This function localizes a neuronal spike by selecting the channels with the
% largest peak‐to‐trough amplitudes, then computing either a weighted center‐of‐mass
% in two dimensions or fitting a monopolar triangulation model to infer depth.
%
% Inputs:
%   waveforms_mean       double (n_channel × n_sample)
%       Mean waveform for each recording channel.
%
%   channel_locations    double (n_channel × 2)
%       [x, y] coordinates of each channel on the probe.
%
%   n_nearest_channels   double scalar
%       Number of channels to include around the largest‐amplitude channel.
%       Default: 20.
%
%   algorithm            char or string
%       'center_of_mass'       return x,y via weighted average and z = 0;
%       'monopolar_triangulation'       fit amplitude decay model to estimate (x,y,z) and source amplitude.
%       Default: 'monopolar_triangulation'.
%
% Outputs:
%   x                    double scalar
%       Estimated x‐coordinate of the spike source.
%
%   y                    double scalar
%       Estimated y‐coordinate of the spike source.
%
%   z                    double scalar
%       Estimated depth of the spike source (zero for center‐of‐mass).
%
%   ptt                  double scalar
%       Peak‐to‐trough amplitude used for weighting or model fitting.
%
% Reference:
%   Boussard et al., “Three‐Dimensional Spike Localization and Improved Motion
%   Correction for Neuropixels Recordings,” NeurIPS 2021
%
%   See also SpikeInterface localization_tools.py:
%   https://spikeinterface.readthedocs.io/en/stable/modules/postprocessing.html#spike-locations
%   https://github.com/SpikeInterface/spikeinterface/blob/main/src/spikeinterface/postprocessing/localization_tools.py#L334
%
% Date:    20250821  
% Author:  Yue Huang

if nargin < 3
    n_nearest_channels = 20;
end
if nargin < 4
    algorithm = 'monopolar_triangulation';
end

% get n_nearest_channels from the channels with the largest peak-to-trough value
peaks_to_trough = max(waveforms_mean, [], 2) - min(waveforms_mean, [], 2);
[~, idx_max] = max(peaks_to_trough);

loc_max = channel_locations(idx_max, :);
distance_to_max = sum((channel_locations - loc_max).^2, 2);

[~, idx_sorted] = sort(distance_to_max, 'ascend');
idx_included = idx_sorted(1:n_nearest_channels);

% calculate the center_to_mass location
ptt_max = peaks_to_trough(idx_max);
ptt_this = peaks_to_trough(idx_included);
loc_this = channel_locations(idx_included,:);

loc_center_to_mass = sum(loc_this.*ptt_this, 1)./sum(ptt_this);

if strcmpi(algorithm, 'center_of_mass')
    x = loc_center_to_mass(1);
    y = loc_center_to_mass(2);
    z = 0;
    ptt = ptt_max;

    return
end

% calculate the monopolar_triangulation location

% % fminunc
% fun = @(x) sum(...
%     (ptt_this - x(4)./sqrt((loc_this(:,1)-x(1)).^2 + (loc_this(:,2)-x(2)).^2 + x(3).^2)).^2);
% 
% x0 = [loc_center_to_mass, 1, ptt_max];
% 
% options = optimoptions('fminunc', 'MaxFunctionEvaluations', 1e4);
% loc_monopolar_triangulation = fminunc(fun, x0, options);
% x = loc_monopolar_triangulation(1);
% y = loc_monopolar_triangulation(2);

% nonlinear least-square fitting
fun = @(x, loc_this) x(4)./sqrt((loc_this(:,1)-x(1)).^2 + (loc_this(:,2)-x(2)).^2 + x(3).^2);
x_bound_lower = [loc_center_to_mass(1)-100, loc_center_to_mass(2)-100, 0, 0];
x_bound_upper = [loc_center_to_mass(1)+100, loc_center_to_mass(2)+100, 100*10, 1000*ptt_max];
x0 = [loc_center_to_mass, 1, ptt_max];

% disp('Calculating the location...');
options = optimoptions('lsqcurvefit', 'Display', 'off');
loc_monopolar_triangulation = lsqcurvefit(fun, x0, loc_this, ptt_this, x_bound_lower, x_bound_upper, options);
x = loc_monopolar_triangulation(1);
y = loc_monopolar_triangulation(2);
z = loc_monopolar_triangulation(3);
ptt = loc_monopolar_triangulation(4);
end