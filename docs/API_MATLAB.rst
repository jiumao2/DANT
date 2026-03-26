API (MATLAB)
============

.. contents::
   :local:

Data Preparation
----------------

``preprocessSpikeInfo(user_settings, spikeInfo)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Prepare directories, validate and preprocess ``spikeInfo`` structures.

This function creates output and figure folders, checks session index continuity, computes 3D unit locations and amplitudes via ``spikeLocation``, identifies peak channels, optionally centers waveforms on their trough, extracts autocorrelogram and ISI features, and saves intermediate ``spikeInfo`` to disk when requested.

**Inputs**

- ``user_settings``: struct.
- ``user_settings.output_folder``: char or string. Path for saving results and figures.
- ``user_settings.spikeLocation.n_nearest_channels``: double scalar. Number of channels for localization.
- ``user_settings.spikeLocation.location_algorithm``: char. ``center_of_mass`` or ``monopolar_triangulation``.
- ``user_settings.centering_waveforms``: logical scalar. Flag to realign waveforms around the trough.
- ``user_settings.motionEstimation.features``: cell array of char. Features for motion estimation.
- ``user_settings.clustering.features``: cell array of char. Features for clustering.
- ``user_settings.autoCorr.window``: double scalar in ms. Half-width of the autocorrelogram window.
- ``user_settings.autoCorr.binwidth``: double scalar in ms. Bin size for the autocorrelogram.
- ``user_settings.autoCorr.gaussian_sigma``: double scalar. Gaussian smoothing sigma for the autocorrelogram.
- ``user_settings.ISI.window``: double scalar in ms. Bin limits for the ISI histogram.
- ``user_settings.ISI.binwidth``: double scalar in ms. Bin size for the ISI histogram.
- ``user_settings.ISI.gaussian_sigma``: double scalar. Gaussian smoothing sigma for the ISI histogram.
- ``user_settings.save_intermediate_results``: logical scalar. Whether to save ``spikeInfo.mat`` after preprocessing.
- ``spikeInfo``: struct array. Expected fields include ``SessionIndex``, ``Waveform``, ``SpikeTimes``, ``Xcoords``, and ``Ycoords``.

**Output**

- ``spikeInfo``: preprocessed struct array with fields such as ``Location``, ``Amplitude``, ``Channel``, optionally centered ``Waveform``, ``AutoCorr``, and ``ISI``.


``getAllFeatures(spikeInfo)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Extract ISI, autocorrelogram, and PETH feature matrices.

This function gathers available features from a ``spikeInfo`` struct array by concatenating ``.ISI``, ``.AutoCorr``, and ``.PETH`` across units when those fields are present.

**Inputs**

- ``spikeInfo``: struct array.
- Optional fields:
  - ``.ISI``: vector or matrix of ISI features.
  - ``.AutoCorr``: vector or matrix of autocorrelogram features.
  - ``.PETH``: vector or matrix of PETH features.

**Outputs**

- ``ISI_features``: numeric matrix or empty.
- ``AutoCorr_features``: numeric matrix or empty.
- ``PETH_features``: numeric matrix or empty.


``spikeLocation(waveforms_mean, channel_locations, n_nearest_channels, algorithm)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Estimate spike source coordinates from channel waveforms.

This function localizes a neuronal spike by selecting the channels with the largest peak-to-trough amplitudes, then computing either a weighted center of mass in two dimensions or fitting a monopolar triangulation model to infer depth.

**Inputs**

- ``waveforms_mean``: double ``(n_channel x n_sample)``. Mean waveform for each recording channel.
- ``channel_locations``: double ``(n_channel x 2)``. ``[x, y]`` coordinates of each channel on the probe.
- ``n_nearest_channels``: double scalar. Number of channels to include around the largest-amplitude channel. Default: ``20``.
- ``algorithm``: char or string. ``center_of_mass`` or ``monopolar_triangulation``. Default: ``monopolar_triangulation``.

**Outputs**

- ``x``: estimated x coordinate of the spike source.
- ``y``: estimated y coordinate of the spike source.
- ``z``: estimated depth of the spike source. Zero for ``center_of_mass``.
- ``ptt``: peak-to-trough amplitude used for weighting or model fitting.

**Reference**

- Boussard et al., "Three-Dimensional Spike Localization and Improved Motion Correction for Neuropixels Recordings," NeurIPS 2021.
- See also SpikeInterface ``localization_tools.py``.


Similarity and Features
-----------------------

``computeAutoCorr(spike_times, window, binwidth)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Compute the autocorrelogram using spike times without normalization.

``computeAutoCorr`` calculates unnormalized autocorrelation counts by computing time differences between all spike pairs, binning them within plus or minus ``window`` milliseconds at a resolution of ``binwidth``. The lag vector spans from ``-window`` to ``+window`` in steps of ``binwidth``.

**Inputs**

- ``spike_times``: double vector. Spike times in milliseconds.
- ``window``: double scalar in ms. Half-width of the correlogram window. Default: ``300``.
- ``binwidth``: double scalar in ms. Bin width for time differences. Default: ``1``.

**Outputs**

- ``auto_corr``: autocorrelation counts for each lag bin.
- ``lag``: time lag values in ms corresponding to each bin.

**Reference**

- Adapted from the phylib implementation: ``phylib/stats/ccg.py``.


``computeWaveformSimilarityMatrix(user_settings, waveforms_all, channel_locations)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Compute waveform-based similarity matrix across units.

This function identifies nearest channels per unit on the probe, groups units with identical channel neighborhoods, extracts waveform snippets for each template, computes pairwise correlations, applies the Fisher z-transform, symmetrizes correlations, and aggregates the maximum similarity across templates.

**Inputs**

- ``user_settings``: struct.
- ``user_settings.waveformCorrection.n_nearest_channels``: number of neighbors per channel.
- ``waveforms_all``: numeric array ``(n_unit x n_channel x n_sample x n_templates)``. Corrected waveforms for each unit and template.
- ``channel_locations``: numeric matrix ``(n_channel x 2)``. ``[x, y]`` coordinates of probe channels.

**Output**

- ``waveform_similarity_matrix``: numeric matrix ``(n_unit x n_unit)``. Symmetric waveform-based similarity values between units.


``computeAllSimilarityMatrix(user_settings, waveforms_all, channel_locations, ISI_features, AutoCorr_features, PETH_features, feature_names, idx_unit_pairs)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Compute and visualize similarity matrices across multiple features.

This function computes pairwise similarity matrices for waveform, ISI, autocorrelation, and PETH features as specified by ``feature_names``. The resulting matrices are concatenated into a 3D array. A histogram of similarity values for the requested unit pairs is plotted, and figures are optionally saved to disk.

**Inputs**

- ``user_settings``: struct.
- ``user_settings.save_intermediate_figures``: logical scalar. Whether to export figures.
- ``user_settings.output_folder``: char or string. Directory for saved figures.
- ``waveforms_all``: double array ``(n_unit x C x T)``. Waveforms for all units.
- ``channel_locations``: double array ``(C x 2)`` or ``(C x 3)``. Spatial coordinates of each recording channel.
- ``ISI_features``: double matrix. Inter-spike interval features.
- ``AutoCorr_features``: double matrix. Autocorrelation features.
- ``PETH_features``: double matrix. Peristimulus time histogram features.
- ``feature_names``: cell array. Subset of ``{'Waveform','ISI','AutoCorr','PETH'}`` indicating which similarities to compute.
- ``idx_unit_pairs``: integer matrix. Each row contains a pair of unit indices for histogram plotting.

**Outputs**

- ``similarity_matrix_all``: double array ``(n_unit x n_unit x M)``. Stack of similarity matrices, one per feature in ``feature_names_all``.
- ``feature_names_all``: cell array. Names of the features that were computed.


``getNearbyPairs(max_distance, sessions, locations, Motion)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Find all pairs of units whose corrected depth difference does not exceed a specified threshold.

This function applies optional motion correction to raw depths, computes pairwise absolute differences in corrected depth, and returns index pairs ``(i < j)`` and their corresponding session IDs.

**Inputs**

- ``max_distance``: scalar double. Maximum allowed depth difference in um.
- ``sessions``: integer vector. Session index for each unit.
- ``locations``: double matrix ``(n_unit x 2)``. X and Y coordinates of each unit, where Y is raw depth in um.
- ``Motion``: optional struct with fields ``LinearScale``, ``Linear``, and ``Constant``.

**Outputs**

- ``idx_unit_pairs``: integer matrix. Each row ``[i, j]`` contains a pair of unit indices within the depth threshold.
- ``session_pairs``: integer matrix. Corresponding session indices ``[sessions(i), sessions(j)]``.


Motion Correction
-----------------

``initializeMotion(user_settings, waveforms_all, sessions, channel_locations, locations)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Initialize motion correction from pre-computed drift estimates.

This function loads session-wise motion values from a user-specified ``.npy`` file and applies them to correct unit waveforms. If no motion file is provided, raw waveforms are returned unchanged. The function constructs a ``Motion`` struct with constant offsets assuming rigid motion.

**Inputs**

- ``user_settings``: struct.
- ``user_settings.waveformCorrection.path_to_motion``: char or string. Path to a pre-computed motion ``.npy`` file, one value per session.
- ``waveforms_all``: double ``(n_unit x n_channel x n_sample)``. Raw waveform snippets for each unit.
- ``sessions``: integer vector. Session index for each unit.
- ``channel_locations``: double ``(n_channel x 2)``. X and Y coordinates of each recording channel.
- ``locations``: double ``(n_unit x 2)``. X and Y coordinates of the peak waveform location for each unit.

**Outputs**

- ``waveforms_corrected``: double ``(n_unit x n_channel x n_sample x n_templates)``. Corrected waveform templates for each unit.
- ``Motion``: struct with fields ``LinearScale``, ``Linear``, and ``Constant``.


``computeMotion(user_settings, similarity_matrix, hdbscan_matrix, idx_unit_pairs, similarity_thres, sessions, locations)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Estimate session-to-session probe drift from matched unit pairs.

This function estimates depth motion across recording sessions by fitting depth-correction parameters to reliable unit matches and computing confidence intervals. It selects unit pairs exceeding a similarity threshold and sharing cluster membership, computes raw depth differences and mean depths, fits either a linear-correction model or a default offset model, uses bootstrapping to derive 95 percent confidence intervals, and generates diagnostic plots.

**Inputs**

- ``user_settings``: struct.
- ``user_settings.waveformCorrection.linear_correction``: logical. Whether to use the linear correction model.
- ``user_settings.save_intermediate_figures``: logical. Whether to export diagnostic figures.
- ``user_settings.save_intermediate_results``: logical. Whether to save intermediate results.
- ``user_settings.output_folder``: char or string. Directory for saving figures and results.
- ``similarity_matrix``: double matrix ``(n_unit x n_unit)``. Pairwise similarity values between all units.
- ``hdbscan_matrix``: logical matrix ``(n_unit x n_unit)``. Adjacency matrix of final HDBSCAN clusters.
- ``idx_unit_pairs``: integer matrix. Unit-pair indices evaluated for motion estimation.
- ``similarity_thres``: double scalar. Similarity threshold used to select good pairs.
- ``sessions``: integer vector. Session index for each unit.
- ``locations``: double matrix ``(n_unit x 2)``. X and Y coordinates of each unit on the probe.

**Output**

- ``Motion``: struct with fields ``Linear``, ``Constant``, and ``LinearScale``.


``computeCorrectedWaveforms(user_settings, waveforms_all, channel_locations, sessions, locations, Motion)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Apply motion-based correction to waveform templates.

This function generates multiple corrected waveform templates for each unit by shifting the waveform extraction depth according to estimated motion parameters. When two templates are requested, one uses the minimum and the other the maximum estimated motion shift.

**Inputs**

- ``user_settings``: struct.
- ``user_settings.waveformCorrection.n_templates``: integer scalar. Number of correction templates to compute.
- ``waveforms_all``: double ``(n_unit x n_channel x n_sample)``. Raw waveform snippets for each unit.
- ``channel_locations``: double ``(n_channel x 2)``. X and Y coordinates of each recording channel.
- ``sessions``: integer vector. Session index for each unit.
- ``locations``: double ``(n_unit x 2)``. X and Y coordinates of the peak waveform location for each unit.
- ``Motion``: struct with fields ``LinearScale``, ``Linear``, and ``Constant``.

**Output**

- ``waveforms_corrected``: double ``(n_unit x n_channel x n_sample x n_templates)``. Corrected waveform templates for each unit under each motion-correction template.


``waveformEstimation(waveform_mean, location, channel_locations, location_new)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Interpolate waveform mean to a shifted probe location using 2D kernel methods.

This function performs Kriging-style interpolation of the mean waveform across recording channels. It computes a spatial kernel matrix between the original channel positions and those displaced by the difference between ``location_new`` and ``location``. The resulting interpolation matrix is applied to ``waveform_mean`` to estimate the waveform at the new location.

**Inputs**

- ``waveform_mean``: double ``(n_channel x n_sample)``. Mean waveform values across channels and time samples for one unit.
- ``location``: double ``(1 x 2)``. ``[x, y]`` coordinates of the original waveform peak on the probe.
- ``channel_locations``: double ``(n_channel x 2)``. ``[x, y]`` coordinates of each recording channel on the probe.
- ``location_new``: double ``(1 x 2)``. ``[x, y]`` target coordinates for interpolation.

**Output**

- ``waveform_out``: double ``(n_channel x n_sample)``. Interpolated waveform mean at the new probe location.


``computeKernel2D(xp, yp, sig)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Compute anisotropic exponential kernel between 2D coordinate sets as Kilosort2.5 does.

This function computes a pairwise kernel matrix using separable exponential decay in x and y. It calculates horizontal and vertical distances, applies anisotropic scaling with horizontal scale ``sig`` and vertical scale ``1.5*sig``, and returns the resulting kernel matrix.

**Inputs**

- ``xp``: double matrix ``(n1 x 2)``. ``[x, y]`` coordinates of the first point set.
- ``yp``: double matrix ``(n2 x 2)``. ``[x, y]`` coordinates of the second point set.
- ``sig``: double scalar. Base scale for horizontal distances. Default: ``20``.

**Output**

- ``K``: double matrix ``(n1 x n2)``. Kernel values between each ``xp`` and ``yp`` coordinate pair.


``lossFunLinearCorrection(params, sessions_pairs, dy, depth, linear_scale, n_session)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Loss function for linear session-to-session depth correction.

This function computes the sum of squared errors between predicted depth displacements and observed shifts. It parses ``params`` into per-session linear and constant offsets with session 1 fixed at zero, predicts displacements, and calculates the total squared-error loss across all unit pairs.

**Inputs**

- ``params``: double vector. Concatenated linear and constant terms, with session 1 fixed at zero.
- ``sessions_pairs``: integer matrix ``(2 x n_pairs)``. Session indices ``[sess_i; sess_j]`` for each observed pair.
- ``dy``: double vector. Observed depth difference for each pair.
- ``depth``: double vector. Raw depth of the first-session unit in each pair.
- ``linear_scale``: double scalar. Global scaling factor applied to linear terms.
- ``n_session``: integer scalar. Total number of recording sessions.

**Output**

- ``loss``: double scalar. Sum of squared errors between predicted and observed displacements.


``lossFunLinearDefault(params, sessions_pairs, dy)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Loss function for default linear session depth correction.

This function computes squared-error loss between session-to-session parameter offsets and observed depth differences.

**Inputs**

- ``params``: double vector. Per-session depth offset parameters.
- ``sessions_pairs``: integer matrix ``(2 x n_pairs)``. Session index pairs ``[sess_i; sess_j]`` for each observation.
- ``dy``: double vector. Observed depth difference for each pair.

**Output**

- ``loss``: double scalar. Sum of squared errors between predicted and observed depth shifts.


Clustering and Curation
-----------------------

``iterativeClustering(user_settings, path_DANT, similarity_matrix_all, feature_names, idx_unit_pairs, sessions)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Iterative HDBSCAN clustering with adaptive feature weighting.

This function performs iterative HDBSCAN clustering on unit similarity data. It combines multiple similarity features into a single weighted similarity matrix, executes HDBSCAN through the Python wrapper, updates feature weights between iterations using LDA on matched versus unmatched pairs, and derives final clusters, a similarity threshold, and reliable-match adjacency.

**Inputs**

- ``user_settings``: struct.
- ``user_settings.clustering.n_iter``: number of HDBSCAN-LDA iterations.
- ``user_settings.clustering.weight_tol``: tolerance for early stopping based on weight changes.
- ``user_settings.output_folder``: directory for settings and outputs.
- ``user_settings.path_to_python``: path to the Python executable.
- ``path_DANT``: char. Path to the DANT repo containing ``main_hdbscan.py``.
- ``similarity_matrix_all``: double ``(n_unit x n_unit x n_features)``. Pairwise similarity values for each feature.
- ``feature_names``: cell array. Names of the similarity features.
- ``idx_unit_pairs``: integer matrix. Unit-pair indices used to flatten feature values.
- ``sessions``: integer vector. Session index for each unit.

**Outputs**

- ``hdbscan_matrix``: logical ``(n_unit x n_unit)``. Final cluster adjacency after the last iteration.
- ``idx_cluster_hdbscan``: integer vector. Cluster labels for each unit, with ``-1`` for noise.
- ``similarity_matrix``: double ``(n_unit x n_unit)``. Weighted sum of feature similarities used for clustering.
- ``similarity_all``: double ``(n_pairs x n_features)``. Flattened feature matrix for ``idx_unit_pairs``.
- ``weights``: double vector. Learned feature weights from the final LDA.
- ``thres``: double scalar. Similarity threshold for defining good matches.
- ``good_matches_matrix``: logical ``(n_unit x n_unit)``. Adjacency of unit pairs exceeding the similarity threshold.
- ``leafOrder``: integer vector. Optimal leaf ordering from hierarchical linkage when requested.


``autoCuration(user_settings, hdbscan_matrix, idx_cluster_hdbscan, good_matches_matrix, sessions, similarity_matrix)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Automatically curate HDBSCAN clustering by removing invalid units and splitting clusters.

This function removes units from clusters if they originate from the same session or have low similarity, optionally splits clusters based on connectivity in ``good_matches_matrix``, records every curation action, and returns updated cluster assignments, adjacency, and removal statistics.

**Inputs**

- ``user_settings``: struct.
- ``user_settings.autoCuration.auto_split``: logical scalar. Whether to enable cluster splitting.
- ``hdbscan_matrix``: logical matrix ``(n_unit x n_unit)``. Initial adjacency matrix of cluster membership.
- ``idx_cluster_hdbscan``: integer vector. Initial cluster labels for each unit.
- ``good_matches_matrix``: logical matrix ``(n_unit x n_unit)``. Adjacency of reliable matches used for subcluster detection.
- ``sessions``: integer vector. Session identifiers for each unit.
- ``similarity_matrix``: double matrix ``(n_unit x n_unit)``. Pairwise similarity values used for filtering low-similarity units.

**Outputs**

- ``hdbscan_matrix``: updated adjacency matrix after removals and splits.
- ``idx_cluster_hdbscan``: updated cluster labels for each unit.
- ``curation_pairs``: integer matrix. Each row is a pair of unit indices involved in a curation action.
- ``curation_types``: integer vector. Action type for each pair.
- ``curation_type_names``: cell array. Names of curation action types.
- ``num_removal``: integer scalar. Total number of unit-pair removals performed.


``graphEditNumber(matA, matB)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Compute the number of minimal edges in two graphs and their overlap.

This function converts adjacency matrices into MATLAB graph objects, finds connected components, sums component sizes minus one for each graph, and computes the same quantity for the intersection graph.

**Inputs**

- ``matA``: logical matrix ``(n x n)``. Adjacency matrix of graph A.
- ``matB``: logical matrix ``(n x n)``, optional. Adjacency matrix of graph B. If omitted, ``matB = matA``.

**Outputs**

- ``nSame``: integer scalar. Number of edges common to both graphs.
- ``nA``: integer scalar. Total number of edges in graph A.
- ``nB``: integer scalar. Total number of edges in graph B.


Output and Visualization
------------------------

``mergeOutput(user_settings, spikeInfo, shanks_data, output_folder)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Combine per-shank clustering and waveform outputs into one result.

This function loads individual shank results from ``Output.mat`` and ``Waveforms.mat``, concatenates cluster assignments, similarity data, curation logs, motion parameters, and corrected waveforms into a single unified ``Output`` struct, and saves the merged output back to disk.

**Inputs**

- ``user_settings``: struct.
- ``user_settings.waveformCorrection.n_templates``: integer. Number of templates per unit for waveform correction.
- ``spikeInfo``: struct array. Preprocessed spike data for each unit.
- ``shanks_data``: integer vector. Shank ID assignment for each unit.
- ``output_folder``: char or string. Root directory containing ``Shank<ID>`` subfolders with saved results.

**Output**

- ``Output``: merged struct containing global indices, cluster assignments, similarity data, curation logs, session information, motion parameters, runtime, and timestamp.


``saveToOutput(user_settings, spikeInfo, idx_clusters, cluster_matrix, locations, leafOrder, similarity_matrix, similarity_all, idx_unit_pairs, similarity_names, weights, thres, good_matches_matrix, sessions, Motion, idx_units, tic_start, curation_pairs, curation_types, curation_type_names, num_removal)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Create and save the ``Output`` struct with clustering and similarity results.

This function assembles clustering labels, similarity metrics, curation history, and metadata into an ``Output`` struct, writes it to ``Output.mat`` in the specified folder, and prints a summary to the command window.

**Inputs**

- ``user_settings``: struct containing analysis parameters and I/O settings, including ``output_folder``.
- ``spikeInfo``: struct array with optional fields such as ``Session``, ``ISI``, ``AutoCorr``, ``PETH``, ``Xcoords``, and ``Ycoords``.
- ``idx_clusters``: integer vector. Cluster label assigned to each unit.
- ``cluster_matrix``: logical or double adjacency matrix of unit co-membership before curation.
- ``locations``: double matrix. Unit coordinates.
- ``leafOrder``: integer vector. Order of units after hierarchical leaf sorting.
- ``similarity_matrix``: double matrix. Final similarity matrix.
- ``similarity_all``: double matrix. Raw similarity values for unit pairs and features.
- ``idx_unit_pairs``: integer matrix. Indices of unit pairs corresponding to rows of ``similarity_all``.
- ``similarity_names``: cell array. Names of similarity features.
- ``weights``: double vector. Weights applied to each similarity feature.
- ``thres``: double scalar or vector. Threshold used to define good matches.
- ``good_matches_matrix``: logical matrix. Binary mask of pairwise similarities above threshold.
- ``sessions``: integer vector. Session index for each unit.
- ``Motion``: struct with motion parameters.
- ``idx_units``: integer vector. Original unit indices before sorting.
- ``tic_start``: scalar returned by ``tic``.
- ``curation_pairs``: integer matrix. Unit pairs removed or split during curation.
- ``curation_types``: integer vector. Curation action types.
- ``curation_type_names``: cell array. Names of curation types.
- ``num_removal``: integer scalar. Total number of removals during auto-curation.

**Output**

- ``Output``: struct with fields including ``NumClusters``, ``NumUnits``, ``IdxUnit``, ``Locations``, ``IdxSort``, ``IdxCluster``, ``SimilarityMatrix``, ``SimilarityAll``, ``SimilarityPairs``, ``SimilarityNames``, ``SimilarityWeights``, ``SimilarityThreshold``, ``GoodMatchesMatrix``, ``ClusterMatrix``, ``MatchedPairs``, ``CurationPairs``, ``CurationTypes``, ``CurationTypeNames``, ``CurationNumRemoval``, ``Params``, ``NumSession``, ``Sessions``, ``Motion``, optional ``SessionNames``, ``RunTime``, and ``DateTime``.


``overviewResults(user_settings, Output)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Create an integrated figure summarizing clustering and tracking.

This function generates a multi-panel overview figure that includes unit count per session against probe depth, motion-corrected probe positions over sessions, histograms of similarity distributions for matched versus unmatched pairs, scatter plots of pairwise similarity metrics, probability of a match as a function of session lag, a presence matrix of unique neurons across sessions, and a session-by-session similarity heatmap.

**Inputs**

- ``user_settings``: struct.
- ``user_settings.output_folder``: char or string. Base folder for saving figures.
- ``Output``: struct with fields such as ``NumSession``, ``NumClusters``, ``NumUnits``, ``Sessions``, ``Locations``, ``Motion``, ``IdxCluster``, ``SimilarityAll``, ``SimilarityNames``, ``SimilarityWeights``, ``SimilarityThreshold``, ``SimilarityPairs``, and ``SimilarityMatrix``.

**Output**

- Saves the overview figure to ``fullfile(user_settings.output_folder, 'Figures', 'Overview.png')``.


``visualizeCluster(Output, cluster_id, spikeInfo, waveforms, user_settings)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Visualize properties of a single cluster across sessions and features.

This function generates a multi-panel figure for a selected cluster. It includes probe depth versus session index, overlaid waveforms arranged by channel positions, feature traces for ISI, autocorrelation, and PETH, and two-dimensional scatter plots and similarity matrices for unit pairs.

**Inputs**

- ``Output``: struct containing cluster labels, sessions, motion parameters, locations, similarity pairs, similarity values, similarity names, similarity weights, and the final similarity matrix.
- ``cluster_id``: integer scalar. Cluster label to visualize.
- ``spikeInfo``: struct array with fields such as ``ISI``, ``AutoCorr``, ``PETH``, ``Xcoords``, and ``Ycoords``.
- ``waveforms``: double array ``(n_units x n_channels x n_samples x n_templates)``. Waveform snippets for each unit.
- ``user_settings``: struct with fields such as ``clustering.max_distance`` and ``output_folder``.

**Output**

- This function does not return variables. It creates and saves a figure summarizing cluster-specific depth, waveform, feature, and similarity information.
