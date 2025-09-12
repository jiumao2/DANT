Overview
================

DANT is a MATLAB toolbox for tracking the neurons across days with high-density probes (Neuropixels).

Check out the Python version of DANT `here <https://github.com/jiumao2/pyDANT>`_!  


Pipeline
----------------
.. image:: ./images/Pipeline.png
   :width: 100%
   :align: center

DANT takes the well spike-sorted data as inputs and assigns a unique cluster ID for each unit as outputs. DANT does not require user-defined "threshold" to filter for the good matches, and thus provides a fully automatic way to track the same neurons across days to months. 

Following spike sorting of each session (1, 2, ..., n) independently, each presumed single-unit was assigned a unique ID (k=1,2,,K; Step 1 or S1 for short). :doc:`Features <Features>` for similarity analysis were extracted from each unit (S2), including :ref:`spike waveforms <waveform_similarity_label>` across a designated channel set (typically the entire recording shank), :ref:`autocorrelograms (ACGs) <Autocorrelogram_feature_label>`, and :ref:`peri-event time histograms (PETHs) or peri-stimulus time histograms (PSTHs) <PETH_feature_label>` reflecting functional properties (optitional). :ref:`Similarity scores <weighted_similarity_label>` between unit pairs were computed using default weights (1/3 for each feature, S3), and nominal distances were calculated to quantify pairwise similarity. Using the distance, :ref:`density-based clustering <iterative_motion_correction_label>` identified matched units hypothesized to originate from the same neuron (S4). :ref:`Linear discriminant analysis (LDA) <weighted_similarity_label>` was then applied to derive weights maximizing discrimination between matched and unmatched pairs (S5), yielding updated similarity scores (S6). Clustering was iterated until weights stabilized and clustering results converged. Using spatial information from matched pairs, relative :ref:`probe movement <motion_estimation_label>` across sessions was inferred (S7), and spike waveforms were :ref:`remapped <waveform_correction_label>` to probe recording sites, correcting for movement (S8). With updated waveforms and optimized weights, similarity scores were recomputed, and clustering was repeated (S9-S11). A :doc:`quality control step <Auto_curation>` (S12) removed pairs within clusters failing LDA-derived similarity criteria. Clusters were then assigned IDs representing groups of units recorded across multiple sessions (2 to n) hypothesized to originate from the same neuron. Notably, the procedure required no user intervention: clustering was unsupervised, and LDA, while supervised, relied on clustering outcomes.

The pipeline contains 2 loops: :ref:`motion correction loop <iterative_motion_correction_label>` (S3 - S9) and :ref:`clustering loop <iterative_clustering_algorithm_label>` (S4 - S12). The loops are designed to optimized the estimated probe motion, feature weights, and clustering results in a alternative manner. Click on them for details.



