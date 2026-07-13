Features
===========

To compare the similarity between two units, we use informative features that help discriminate between matched and unmatched pairs. These features include:

- Waveform

- Peri-event time histogram (PETH)

- Autocorrelogram

- Inter-spike interval histogram (ISI)

.. _waveform_similarity_label:

Waveform
-----------

.. image:: ./images/WaveformSimilarity.png
    :width: 60%
    :align: center

We compute the Pearson correlation coefficient between raw or motion-corrected waveforms :math:`\mathbf{W}` from the :math:`n` nearest channels (:math:`n = 38` by default; see :ref:`Change default settings <waveform_correction_n_nearest_channels_label>`), and then apply Fisher's z-transform:

.. math::
    Z_{i,j} =
    \tanh^{-1}(\operatorname{corrcoef}(\mathbf{W}^{i}_{\mathcal{C_i}},
    \mathbf{W}^{j}_{\mathcal{C_i}}))

and

.. math::
    Z_{j,i} =
    \tanh^{-1}(\operatorname{corrcoef}(\mathbf{W}^{i}_{\mathcal{C_j}},
    \mathbf{W}^{j}_{\mathcal{C_j}})),

where :math:`\mathcal{C_i}` indexes the :math:`n` nearest channels from the peak channel (the channel with maximum amplitude) of unit :math:`i`. :math:`\mathbf{W}^{j}_{\mathcal{C_i}}` is the waveform of unit :math:`j` extracted from the channel indices :math:`\mathcal{C_i}`. Because different units can have different peak channels, :math:`Z_{i,j}` may not be equal to :math:`Z_{j,i}`. To make the similarity score symmetric, we compute the final similarity score as

.. math::
    \mathbf{S}_{\text{wf}}^{i,j} = \operatorname{max}(Z_{i,j}, Z_{j,i}).

.. _PETH_feature_label:

Peri-event time histogram (PETH)
-------------------------------------

.. image:: ./images/PETH_Similarity.png
    :width: 40%
    :align: center

The PETH feature is precomputed during data processing. It captures the functional properties of each unit as a vector. As shown in the figure, we combined three different PETHs (lever-press, lever-release, and poke; see the `paper <https://www.jneurosci.org/content/45/16/e1820242025>`_ for details about the task) to form the PETH feature vector. The PETH similarity score between unit :math:`i` and unit :math:`j` is

.. math::
    \mathbf{S}^{i,j}_{\text{PETH}} = \tanh^{-1}(\operatorname{corrcoef}(\text{PETH}_i, \text{PETH}_j)).

If some PETH bins are missing, they can be marked as ``NaN``. DANT computes PETH similarity from the overlapping non-NaN elements for each unit pair.

.. _Autocorrelogram_feature_label:

Autocorrelogram
-------------------

.. image:: ./images/AutoCorrSimilarity.png
    :width: 40%
    :align: center

We compute the autocorrelogram for each unit within a maximum lag of 300 ms, using a bin width of 1 ms. The lag and bin width can be adjusted in ``settings.json`` (see :ref:`Change default settings <autocorr_setting_label>`). The distribution is then smoothed with a Gaussian kernel (:math:`\sigma = 5` ms) and zeroed at lag 0. The autocorrelogram similarity score between unit :math:`i` and unit :math:`j` is

.. math::
    \mathbf{S}^{i,j}_{\text{AC}} = \tanh^{-1}(\operatorname{corrcoef}(\text{AC}_i, \text{AC}_j)).

Note that this feature basically encodes the same information as the inter-spike interval histogram (ISI). For that reason, do not use these two features together, as doing so will cause collinearity and impair LDA performance.

Inter-spike interval histogram (ISI)
-----------------------------------------

.. image:: ./images/ISI_Similarity.png
    :width: 40%
    :align: center

This feature is not used in DANT by default because it basically encodes the same information as the autocorrelogram. Using the two features together will cause collinearity and impair LDA performance. Still, it remains available as a feature option. We compute the ISI for each unit within a window of 100 ms, using a bin width of 1 ms by default. The lag and bin width can be adjusted in ``settings.json`` (see :ref:`Change default settings <ISI_setting_label>`). The distribution is then smoothed with a Gaussian kernel (:math:`\sigma = 1` ms). The ISI similarity score between unit :math:`i` and unit :math:`j` is

.. math::
    \mathbf{S}^{i,j}_{\text{ISI}} = \tanh^{-1}(\operatorname{corrcoef}(\text{ISI}_i, \text{ISI}_j)).

How to choose the features
--------------------------------

.. image:: ./images/WeightsDistribution.png
    :width: 80%
    :align: center

|

Different features contribute differently to unit identity. We evaluated the importance of each feature by calculating the AUC (area under the ROC curve) between matched and unmatched pairs. The weights derived from LDA (see :ref:`Clustering <weight_optimization_label>`) also reflected how strongly each feature helped separate matched and unmatched pairs. 
In our datasets, the waveform feature played the most important role in tracking neurons, followed by the PETH feature. The autocorrelogram feature was the least informative (similar to the ISI feature; data not shown). Keep in mind that the PETH feature depends on many factors, such as the task and the brain region, so it is not guaranteed to improve neuron tracking. In this case, the mPFC datasets showed a weaker PETH feature because task-related modulation was weaker than in the motor cortex. 

.. _weighted_similarity_label:

Weighted similarity
-----------------------

Because the clustering algorithm requires a single value, we combine the different similarity scores into one value that captures the similarity or distance between any two units. 

The final similarity score is the weighted average of :math:`\mathbf{S}_{\text{wf}}`, :math:`\mathbf{S}_{\text{AC}}`, and :math:`\mathbf{S}_{\text{PETH}}`, which we compute as follows:

.. math::
    \mathbf{S}=w_{\text{wf}}\mathbf{S}_{\text{wf}}+w_{\text{AC}}\mathbf{S}_{\text{AC}}+w_{\text{PETH}}\mathbf{S}_{\text{PETH}}

and 

.. math::
    w_{\text{wf}} + w_{\text{AC}} + w_{\text{PETH}} = 1,

where :math:`w_{\text{wf}}`, :math:`w_{\text{AC}}` and :math:`w_{\text{PETH}}` are the weights for the waveform, autocorrelogram and PETH similarity scores, respectively. These weights were initialized equally and optimized iteratively (see :ref:`Weight optimization <weight_optimization_label>`). PETH features may be excluded in some studies, reducing the equation to:

.. math::
    \mathbf{S}=w_{\text{wf}}\mathbf{S}_{\text{wf}}+w_{\text{AC}}\mathbf{S}_{\text{AC}}
    
and

.. math::
    w_{\text{wf}} + w_{\text{AC}} = 1.







