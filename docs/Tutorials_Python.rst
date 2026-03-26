Tutorials (Python)
==================

Run the tutorial in Colab: |colab_badge|

.. |colab_badge| image:: https://colab.research.google.com/assets/colab-badge.svg
   :target: https://colab.research.google.com/github/jiumao2/pyDANT/blob/master/pyDANT_demo.ipynb
   :alt: Run the tutorial in Colab

This tutorial walks you through how to use the pyDANT package to track neurons across sessions. It is designed to help you prepare your data and run the code effectively. Before starting, make sure pyDANT is installed correctly. If you have not installed pyDANT yet, please refer to the :doc:`Installation <Installation>` section.

.. _prepare_the_data_python_label:

Prepare the data
-----------------------

An example dataset is available `here <https://figshare.com/articles/dataset/Example_Dataset_for_pyDANT/30596303>`_. You can download it and follow the steps below to run the full example. You can also use your own dataset by following the same workflow.

To use pyDANT, organize your data in a folder with the following structure:

.. code-block::

    data_folder
    ├── channel_locations.npy
    ├── waveform_all.npy
    ├── session_index.npy
    ├── peth.npy (optional)
    └── spike_times/
        ├── Unit0.npy
        ├── Unit1.npy
        ├── Unit2.npy
        ├── ...
        └── UnitN.npy

- The data files should follow the formats below:

===========================    ======================================  =================================================
Filename                       Shape                                   Explanation  
===========================    ======================================  =================================================
``session_index.npy``          (n_unit,)                               indicates the session. It should start from 1 (for compatibility with MATLAB) and be continuous without any gaps.
``waveform_all.npy``           (n_unit, n_channel, n_sample)           the mean waveform of each unit in μV. All units must share the same set of channels                         
``channel_locations.npy``      (n_channel, 2)                          x and y coordinates of each channel in μm. The y coordinate typically represents depth
``peth.npy``                   (n_unit, n_point)                       optional, peri-event time histogram for each unit
``spike_times/UnitX.npy``      (n_spike,)                              spike times in milliseconds
===========================    ======================================  =================================================

Crucially, the waveforms used in this analysis must not be whitened, unlike the waveforms processed by Kilosort. Avoid direct use of waveforms from ``temp_wh.dat`` and refrain from using ``whitening_mat_inv.npy`` or ``whitening_mat.npy`` from Kilosort2.5 / Kilosort3 to "unwhiten" data. These matrices do not correspond to Kilosort's original whitening process (see this `issue <https://github.com/cortex-lab/phy/issues/1040>`_).

We recommend analyzing data from different brain regions (e.g., cortex and striatum) separately, as they may exhibit distinct drifts and neuronal properties. Please generate a separate data folder for each brain region.

- Copy ``settings.json`` and ``mainDANT.py`` from the pyDANT package into your data folder. A typical layout is shown below:

.. code-block::

    data_folder
    ├── settings.json
    ├── mainDANT.py
    ├── channel_locations.npy
    ├── waveform_all.npy
    ├── session_index.npy
    ├── peth.npy (optional)
    └── spike_times/
        ├── Unit0.npy
        ├── Unit1.npy
        ├── Unit2.npy
        ├── ...
        └── UnitN.npy

Edit the settings
-----------------------

To run pyDANT, edit the ``settings.json`` file in your data folder first. At a minimum, you should specify the following fields:

.. code-block:: json

    {
        "path_to_data": ".", // path to the input data folder
        "output_folder": ".\\DANT_Output", // output folder
    }

If you do not want to use the PETH feature, remove it from both the ``motionEstimation`` and ``clustering`` sections. After editing, the settings can look like this:

.. code-block:: json

    // parameters for motion estimation
    "motionEstimation":{
        "features": [
            ["Waveform", "AutoCorr"],
            ["Waveform", "AutoCorr"]
        ] // features used for motion estimation each iteration. Choose from "Waveform", "AutoCorr", "ISI", "PETH"
    },

and 

.. code-block:: json

    // parameters for clustering
    "clustering":{
        "max_distance": 100, // um. Unit pairs with distance larger than this value in Y direction will be considered as different clusters
        "features": ["Waveform", "AutoCorr"], // features used for final clustering. Choose from "Waveform", "AutoCorr", "ISI", "PETH"
        "n_iter": 10 // number of iterations for the clustering algorithm
    },

Also edit ``mainDANT.py`` to specify the path to the settings file:

.. code-block:: Python

    path_settings = r'./settings.json' # Path to your settings.json file

To learn more about the settings, please refer to the :doc:`Change default settings <Change_default_settings>` section. Careful tuning can help improve tracking results.

Run the code
-----------------------

Run ``mainDANT.py`` in your Python environment from the terminal or command prompt:

.. code-block::

    python mainDANT.py


The tracking results should appear in the output folder specified in ``settings.json``. A typical output layout looks like this:

.. code-block::

    data_folder
    ├── settings.json
    ├── mainDANT.py
    ├── channel_locations.npy
    ├── waveform_all.npy
    ├── session_index.npy
    ├── peth.npy (optional)
    ├── spike_times/
    └── DANT_Output/
        ├── IdxCluster.npy
        ├── ClusterMatrix.npy
        ├── SimilarityMatrix.npy
        ├── ...
        └── Figures/


.. _output_python_label:

Understand the output
-----------------------

Along with several intermediate files, the main output is stored in the ``DANT_Output`` folder. The most important files are listed below:

===========================     =============================               =================
Field name                      Shape                                       Explanation  
===========================     =============================               =================
``IdxCluster.npy``              (n_unit,)                                   cluster index for each unit.
``ClusterMatrix.npy``           (n_unit x n_unit)                           cluster assignment matrix. ``ClusterMatrix(i,j) = 1`` means unit ``i`` and ``j`` are in the same cluster.
``MatchedPairs``                (n_pairs x 2)                               unit index for all matched pairs.
``SimilarityMatrix``            (n_unit x n_unit)                           weighted sum of the similarity between each pair of units.
===========================     =============================               =================

The most important file is ``IdxCluster.npy``, which assigns a unique cluster ID to each unit (-1 for non-matched units). You can use it to extract matched units across sessions. To learn more about the output, please refer to the :doc:`Input and Output <IO>` section.

Tracking is complete. You can now move on to cross-session analysis with the tracked neurons.
