Input and Output (MATLAB)
===========================

.. contents:: 
    :local:

Input
-------

``spikeInfo.mat``
+++++++++++++++++++

See :ref:`prepare_the_data_matlab_label` for how to build it.

``settings.json``
++++++++++++++++++++

See :ref:`prepare_the_data_matlab_label` for how to prepare it.

See :doc:`Change_default_settings` for setting details.


Output
-------------

``Output.mat``
++++++++++++++++

See :ref:`output_matlab_label` for details.

.. _motion_output_label:

``Motion.mat``
++++++++++++++++

For a single-shank run, this file is written when ``save_intermediate_results`` is ``true``. For a multi-shank run, each shank's file is saved in ``Shank<ID>/``. It contains a struct variable named ``Motion``, which stores the estimated probe motion across sessions. The fields are listed below:

===========================     =============================               =================
Field name                      Type                                        Explanation  
===========================     =============================               =================
``Linear``                      1 x n_session double                        linear component of the motion
``Constant``                    1 x n_session double                        constant component of the motion. If the correction is rigid, it is the probe motion.
``LinearScale``                 1 x 1 double                                0.001 by default. It scales the Y position for numerical stability during motion estimation
===========================     =============================               =================

The probe positions across sessions at a given Y position ``y`` can be computed as follows:

.. code-block:: MATLAB

    probe_positions = Motion.LinearScale*Motion.Linear*y + Motion.Constant;

See :ref:`Non-rigid correction <non_rigid_correction_label>` for details.


``Waveforms.mat``
+++++++++++++++++++

This file contains a variable named ``waveforms_corrected``, which is a n_unit x n_channel x n_sample x n_templates array. It stores the corrected waveform templates for all units across all channels.


``resultIter.mat``
++++++++++++++++++++

For a multi-shank run, this file is saved in each ``Shank<ID>/`` folder. It contains a variable named ``resultIter``, which is a 1 x ``n_iter`` struct array. ``n_iter`` is the number of accepted motion-correction iterations saved before the loop finished. If early stopping rejects a new motion estimate, that rejected iteration is not kept in ``resultIter``. The fields are listed below:

===========================     =============================               =================
Field name                      Type                                        Explanation  
===========================     =============================               =================
``FeatureNames``                1 x n_feature cell array                    features used in this iteration
``Weights``                     1 x n_feature double                        optimized weights in this iteration
``IdxClusters``                 n_unit x 1 double                           clustering result (cluster index for each unit) in this iteration
``Motion``                      1 x 1 struct                                estimated probe position (see :ref:`Motion <motion_output_label>`) in this iteration
===========================     =============================               =================

``SimilarityMatrix.mat``
+++++++++++++++++++++++++++++

This file is written when ``save_intermediate_results`` is ``true``; for a multi-shank run, it is saved in each ``Shank<ID>/`` folder. It contains two variables named ``feature_names_all`` and ``similarity_matrix_all``.

``similarity_matrix_all`` is a n_unit x n_unit x n_feature 3D array containing all similarity scores for all pairs of units. ``feature_names_all`` is a 1 x n_feature array indexing the features in ``similarity_matrix_all``. Some features are not used in later clustering steps, so their entries will be zero in ``similarity_matrix_all``. PETH similarity is computed from overlapping non-NaN PETH elements.

Intermediate files
+++++++++++++++++++++

These files include ``ClusterIndices.npy``, ``DistanceMatrix.npy``, ``LinkageMatrix.npy``, and ``HDBSCAN_settings.json``. They are used to communicate data between MATLAB and Python when running the HDBSCAN algorithm. 
