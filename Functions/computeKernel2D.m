function K = computeKernel2D(xp, yp, sig)
% COMPUTEKERNEL2D  Compute anisotropic exponential kernel between 2D
% coordinate sets as Kilosort2.5 does.
%
% Computes a pairwise kernel matrix using separable exponential decay in x and y:
% 1. Calculates absolute horizontal distances and vertical distances.
% 2. Applies anisotropic scaling: horizontal scale = sig, vertical scale = 1.5*sig.
% 3. Forms K(i,j) = exp(−(distx/sig)^1 − (disty/(1.5*sig))^1).
%
% Inputs:
%   xp             double matrix (n1 × 2)
%                  [x,y] coordinates of the first point set.
%   yp             double matrix (n2 × 2)
%                  [x,y] coordinates of the second point set.
%   sig            double scalar
%                  Base scale for horizontal distances; vertical uses 1.5*sig (default = 20).
%
% Outputs:
%   K              double matrix (n1 × n2)
%                  Kernel values between each xp and yp coordinate pair.
%
% Date:    20250821  
% Author:  Yue Huang

if nargin < 3
    sig = 20;
end

distx = abs(xp(:, 1) - yp(:, 1)');
disty = abs(xp(:, 2) - yp(:, 2)');

sigx = sig;
sigy = 1.5 * sig;

p = 1;
K = exp(- (distx/sigx).^p - (disty/sigy).^p);

end