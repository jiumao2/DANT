Input and Output (Python)
============================

.. contents:: 
    :local:

Input
-------

Data
+++++

See how to prepare the data :ref:`here <prepare_the_data_python_label>`.

For multi-shank data, the input folder must also include ``channel_shanks.npy``. This file stores the shank ID of each channel and should have shape ``(n_channel,)``. It is optional for single-shank data.

``settings.json``
+++++++++++++++++++++

See how to prepare it :ref:`here <prepare_the_data_python_label>`.

See how to adjust the settings :doc:`here <Change_default_settings>`.


Output
-------------

The output will be saved in the ``output_folder`` specified in ``settings.json``, which are mostly .npy and .npz files.

Results
+++++++++++++

This part is the main output of pyDANT, which contains the estimated cluster IDs for each unit across sessions.

``IdxCluster.npy`` assigns a unique cluster ID for each unit (-1 for non-matched units). You can use it to extract the matched units across sessions. 

``ClusterMatrix.npy`` is a cluster assignment matrix. ``ClusterMatrix(i,j) = 1`` means unit ``i`` and ``j`` are in the same cluster.

``MatchedPairs.npy`` contains the unit index for all matched pairs.

``RunTimeSec.npy`` contains the total run time in seconds.

``Output.npz`` is a compressed file that contains all the above files and some additional information, such as the number of units, sessions, and clusters. It is designed to mimic the ``Output.mat`` file which is the main output of the MATLAB version of DANT.

For multi-shank runs, the root output folder contains merged global outputs using the same data file names as single-shank runs, including ``Output.npz``, ``ClusteringResults.npz``, ``ClusterMatrix.npy``, ``IdxCluster.npy``, ``MatchedPairs.npy``, the similarity matrices, and ``waveforms_corrected.npy``. The root ``Output.npz`` includes ``IdxUnit`` for the original unit indices and ``IdxShank`` for the shank assignment of each unit. Complete per-shank outputs are also saved under ``Shank<ID>/`` folders inside the root output folder.



Features
++++++++++

The feature-related files include ``auto_corr.npy``, ``isi.npy``, ``peth.npy``. These files store the computed features for each unit, which are used in the motion estimation and clustering processes.


Waveforms
++++++++++++

If you choose to center the waveforms, the centered waveforms will be saved in ``waveforms_centered.npy``. And the corrected waveforms will be saved in ``waveforms_corrected.npy``.


Spike location
+++++++++++++++

The estimated locations for each unit will be saved in ``locations.npy``, with the amplitudes and the peak channels saved in ``amplitude.npy`` and ``peak_channels.npy``, respectively.

If ``channel_shanks.npy`` is available, preprocessing also saves ``unit_shanks.npy``. Each unit is assigned to the shank of its peak channel.


Similarity matrix
++++++++++++++++++++

Four similarity matrices will be saved to ``waveform_similarity_matrix.npy``, ``ISI_similarity_matrix.npy``, ``AutoCorr_similarity_matrix.npy`` and ``PETH_similarity_matrix.npy``. If some features are not used, the corresponding matrices will be filled with zeros. The final weighted similarity matrix will be saved in ``SimilarityMatrix.npy``. In multi-shank root outputs, rows and columns remain in the original global unit order. Similarity is only computed within each shank; entries for unit pairs from different shanks are left as uncomputed zero values and are not treated as matches.


Motion correction
++++++++++++++++++++++

The estimated probe motion will be saved in ``motion_linear_scale.npy``, ``motion_linear.npy`` and ``motion_constant.npy``, which can be loaded via ``Motion.load()`` for single-shank or per-shank output folders. In a merged multi-shank root output, ``motion_linear.npy`` and ``motion_constant.npy`` have shape ``(n_shank, n_session)``, and ``motion_linear_scale.npy`` has shape ``(n_shank,)``. If rigid motion correction is used, only ``motion_constant.npy`` is meaningful. See :ref:`here <non_rigid_correction_label>` for details about non-rigid motion correction.


Clustering
++++++++++++++

The clustering-related files include ``DistanceMatrix.npy``, ``SimilarityPairs.npy``, ``SimilarityThreshold.npy`` and ``SimilarityWeights.npy``. These files store the intermediate results of the final clustering process after motion correction. The ``DistanceMatrix.npy`` contains the pairwise distances between units. The ``SimilarityPairs.npy`` contains the unit index for each pair of units within the ``max_distance``. In multi-shank root outputs, pair indices are global unit indices, no cross-shank pairs are included, and ``SimilarityWeights.npy``/``SimilarityThreshold.npy`` store one row/value per shank. See :doc:`Clustering <Clustering>` for details about the meaning of these files.

``ClusteringResults.npz`` is a compressed file that contains the results of the final clustering process after motion correction, which includes more details about the clustering process, like the clustering results before curation.


Curation
++++++++++++

The curation-related information will be saved in ``CurationTypeNames.npy``, ``CurationTypes.npy``, and ``CurationPairs.npy``. It stores the deleted unit pairs and why they are deleted (types). See :doc:`curation <Auto_curation>` for details.




