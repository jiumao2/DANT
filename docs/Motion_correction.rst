Motion correction
==================

Why motion correction
-------------------------

.. image:: ./images/WaveformCorrection.png
   :width: 100%
   :align: center

|

In chronic Neuropixels recordings, the probe is not stationary relative to the brain even if the probe base is tightly fixed to the skull [1]_. Probe displacements can reach tens to hundreds of micrometers in recordings that span weeks. This movement greatly affects the waveforms recorded on each channel site (15-20 μm intervals along the probe). 

In the above figure, the probe moves upward from day 1 to day m, while the recorded neuron remains in the same location relative to the brain (the triangles). This motion causes changes in spike waveforms at the corresponding channel sites. The probe positions relative to the brain are denoted as :math:`p_1` and :math:`p_m` on day 1 and day m. The unit locations relative to the probe tip are denoted as :math:`y_1` and :math:`y_m`, which can be computed from the waveform amplitudes on nearby channels. Therefore, the real probe motion :math:`\Delta p` (namely :math:`p_m - p_1`) can be estimated using the unit motion :math:`y_m - y_1`. Using the first-day probe, we can estimate the day-m waveforms on each channel site by :ref:`Kriging interpolation <waveform_correction_label>`. In this way, we can compare waveforms on the same probe rather than on moved probes. In channel-wise waveform correlation analysis, the corrected waveforms show a much higher correlation coefficient.

Here is how the motion correction algorithm works.


.. _unit_localization_label:

Unit localization
--------------------------

The method for localizing units is well described in Boussard et al. [2]_. Each unit's 3D position is
denoted as {:math:`x`, :math:`y`, :math:`z`}. Channel positions {:math:`x_c`, :math:`y_c`} on the
probe plane follow SpikeGLX/Kilosort conventions, with :math:`z_c` set to
0. Using a monopolar current source model, we estimate the position of
each unit as follows:

.. math::

    \underset{x,y,z,\alpha}{\operatorname{argmin}} \sum_{c \in
    \mathcal{C}}\left(\operatorname{ptt}_{c}-\frac{\alpha}{\sqrt{\left(x-x_{c}\right)^{2}+\left(y-y_{c}\right)^{2}+z^{2}}}\right)^{2}.

Here, :math:`\operatorname{ptt}_c` denotes the peak-to-trough amplitude on
channel :math:`c`. :math:`\mathcal{C}` denotes the indices of the :math:`n` nearest
channels around the peak channel (the channel with the maximum peak-to-trough
value). :math:`n` is 20 in this study. :math:`\alpha` represents the overall signal
magnitude in the model. The optimization is performed using MATLAB's
``lsqcurvefit``. The position :math:`\boldsymbol{y}` of each unit is then used to
estimate probe motion.


.. _motion_estimation_label:

Motion estimation
--------------------------

Probe motion across recording sessions was estimated using matched unit pairs (identified by the clustering algorithm) and their localized spatial positions. Let :math:`N_s` be the total number of sessions, :math:`N_p` the number of matched unit pairs, and :math:`\boldsymbol{p}_s` the probe position for session :math:`s`. For the :math:`i`-th matched pair (:math:`i = 1, \dots, N_p`), let :math:`s_A^{i}` and :math:`s_B^{i}` denote the sessions from which the two matched units originate, with :math:`y_A^i` and :math:`y_B^i` representing their spatial positions along the probe. The probe positions :math:`\boldsymbol{p} = [p_1, \dots, p_{N_s}]` were estimated by solving:

.. math::

    \boldsymbol{p}^* = \underset{\boldsymbol{p}}{\arg\min} \sum_{i=1}^{N_p} [( y_A^i -y_B^i) - (p_{s_A^i} - p_{s_B^i} ) ]^2.

This minimizes the discrepancy between the relative displacements of matched units and the inferred probe motion across sessions. The optimization was performed using MATLAB's ``fminunc``, and mean-subtracted probe positions (:math:`\boldsymbol{p}^* - \text{mean}(\boldsymbol{p}^*)`) were used for waveform correction to center displacements around a common reference. 

DANT also lets you plug in precomputed motion estimates via a ``.npy`` file (see :ref:`here <path_to_motion_label>` for more details). For example, rigid motion estimates derived from other algorithms such as DREDge can be applied directly during waveform correction.

.. _waveform_correction_label:

Waveform correction
--------------------------

We applied the Kriging interpolation method for motion correction, adapting
it to interpolate average waveforms instead of raw recordings. The corrected
waveform :math:`\tilde{\mathbf{W}}` at probe position :math:`v = \{x, y\}` is a
weighted sum of the original waveforms :math:`\mathbf{W}`, weighted by
spatial proximity. The distance matrices between positions
:math:`\boldsymbol{v}_1` and :math:`\boldsymbol{v}_2` were defined as:

.. math::

    \mathbf{D}_x(\boldsymbol{v}_1,\boldsymbol{v}_2) = \lvert
    \boldsymbol{x}_{1}-\boldsymbol{x}^{T}_2 \rvert

and 

.. math::
    \mathbf{D}_y(\boldsymbol{v}_1,\boldsymbol{v}_2) = \lvert
    \boldsymbol{y}_{1}-\boldsymbol{y}^{T}_2 \rvert,

where :math:`\mathbf{D}_x(\boldsymbol{v}_1,\boldsymbol{v}_2)` and
:math:`\mathbf{D}_y(\boldsymbol{v}_1,\boldsymbol{v}_2)` are the distance matrices
between positions :math:`\boldsymbol{v}_1` and positions :math:`\boldsymbol{v}_2` in
the x and y directions, respectively. Let
:math:`\boldsymbol{v_\mathcal{C}} = \{\boldsymbol{x_\mathcal{C}}, \boldsymbol{y_\mathcal{C}}\}`
denote the positions of the channels :math:`\mathcal{C}`. Then, the corrected
waveform :math:`\tilde{\mathbf{W}}` at probe position :math:`v` is computed via

.. math::
    
    K(\boldsymbol{v}_1,\boldsymbol{v}_2) =
    e^{-\frac{\mathbf{D}_x}{\sigma_x}-\frac{\mathbf{D}_y}{\sigma_y}}

and 

.. math::
    \tilde{\mathbf{W}}(v) =
    K(v,\boldsymbol{v_\mathcal{C}})K(\boldsymbol{v_\mathcal{C}},\boldsymbol{v_\mathcal{C}})^{-1}\mathbf{W}_\mathcal{C},

where :math:`K` is a generalized Gaussian kernel. :math:`\sigma_x` and :math:`\sigma_y`
are two parameters controlling the size of the kernel, with
:math:`\sigma_x = 20` and :math:`\sigma_y = 30` in this paper. For cross-session
consistency, all waveforms were aligned to the mean probe position
(reference probe). The corrected waveform :math:`\tilde{\mathbf{W}}` for unit
:math:`i` on the reference probe is

.. math::

    \tilde{\mathbf{W}^i}(\boldsymbol{v}_\mathcal{C}) = K(\boldsymbol{v_\mathcal{C}} - \{0, \boldsymbol{p}_{
    \boldsymbol{s}_i}
    \},\boldsymbol{v_\mathcal{C}})K(\boldsymbol{v_\mathcal{C}},\boldsymbol{v_\mathcal{C}})^{-1}\mathbf{W}_\mathcal{C}^i.

Now, we can compute corrected waveform similarity again, as described :ref:`here <waveform_similarity_label>`.

.. image:: ./images/ProbeTemplatesA.png
   :width: 100%
   :align: center

|

However, this approach has a catch: units on the edges will be omitted. The approach maps all unit waveforms to the same probe template and compares them there. As shown in the figure, because the probe template is set at the center position, units on the edges (black dots) are not included in the template. As a result, matches involving these units cannot be found.

.. image:: ./images/ProbeTemplatesB.png
   :width: 100%
   :align: center

|

To solve this issue, we can set two probe templates: one at the top and one at the bottom (see :ref:`here <n_templates_label>` for how to set the parameter). The omitted units in template A (the purple dots) can be rescued by template B, and vice versa. The waveform similarity between any two units will be the maximum value of the similarity on either probe. As the probe is far longer than the scale of motion, this method guarantees the inclusion of all recorded units.

.. _iterative_motion_correction_label:

Iterative motion correction
----------------------------------------------

.. image:: ./images/IterativeMotionCorrection.png
   :width: 60%
   :align: center

|

In many cases, a single round of motion correction is insufficient to fully resolve probe drift, particularly when the initial match count is low or when large physical displacements render spatial features such as waveforms temporarily unreliable. To address this, DANT employs an iterative refinement strategy in which the pipeline gradually improves alignment over multiple rounds, thereby revealing more unit matches and enabling increasingly precise drift correction.

The feature sets for these iterations are defined in ``settings.json`` as an array of arrays. A robust configuration typically begins with an initial round that uses only temporal features, such as ``AutoCorr`` and ``PETH``, to build a stable baseline. By excluding waveforms in the first round, the system obtains a stable initial estimate that is less sensitive to spatial misalignment. In subsequent rounds, the introduction of waveforms allows the clustering algorithm to identify more matched pairs as the alignment improves. For datasets with small drifts, or when a strong ``PETH`` feature is unavailable, users may choose to include ``Waveform`` features in all rounds.

An example configuration utilizing an initial temporal-only round followed by waveform-based refinement is as follows:

.. code-block:: json

    "features": [
        ["AutoCorr", "PETH"],
        ["Waveform", "AutoCorr", "PETH"],
        ["Waveform", "AutoCorr", "PETH"],
        ["Waveform", "AutoCorr", "PETH"],
        ["Waveform", "AutoCorr", "PETH"],
        ["Waveform", "AutoCorr", "PETH"],
        ["Waveform", "AutoCorr", "PETH"],
        ["Waveform", "AutoCorr", "PETH"],
        ["Waveform", "AutoCorr", "PETH"],
        ["Waveform", "AutoCorr", "PETH"],
        ["Waveform", "AutoCorr", "PETH"]
    ],
    "stop_early": true

The good news is that users do not need to manually determine the exact number of iterations required for a given dataset. By repeating the feature set, for example 10 times, and setting the ``stop_early`` parameter to ``true``, the pipeline automatically monitors the match count after each iteration. If a new motion estimate fails to increase the number of matched unit pairs relative to the previous state, the process terminates immediately and reverts to the last optimal result. This early-stopping mechanism helps maintain stable tracking, prevents overfitting, and reduces computation time by exiting as soon as convergence is reached.

See :ref:`Change default settings <motion_correction_features_label>` for details on modifying these parameters in your specific configuration file.

.. _non_rigid_correction_label:

Non-rigid motion correction
---------------------------

Rigid correction is sometimes not enough. Some datasets exhibit strong depth-dependent probe motion. Kilosort deals with this issue by setting "blocks". The probe is divided into multiple blocks, and motion correction is performed individually in each block. This method is not well suited to neuron tracking problems because the unit distribution is not uniform along the probe. Some blocks may lack enough good units for accurate motion estimation. How, then, can this problem be solved?

.. image:: ./images/NonRigidCorrection.png
   :width: 80%
   :align: center

|

First, take a look at the matched pairs found by DANT with rigid motion correction. The displacements of these matched pairs are perfectly linearly correlated with the depth of these units (left side panel). The difference in displacement is greater than 100 μm between the top region and the bottom region. This means that the brain shrank significantly during this period (right side schematic).

Motivated by this linearity, we developed a new algorithm for non-rigid correction. Following the definition in :ref:`rigid motion estimation <motion_estimation_label>`, we additionally define the depth :math:`d^i` for the :math:`i`-th matched pair as

.. math::

    d^i = \frac{y_A^i + y_B^i}{2}.

And the new objective function will be 

.. math::

    \boldsymbol{k}^*, \boldsymbol{b}^* = \underset{\boldsymbol{k}, \boldsymbol{b}}{\arg\min} \sum_{i=1}^{N_p} [(y_A^i -y_B^i) - [(k_{s_A^i}d^i + b_{s_A^i}) - (k_{s_B^i}d^i + b_{s_B^i}) ] ]^2.

Note that the function collapses to rigid motion correction if we set :math:`k` to 0 in all sessions. To correctly minimize the function, :math:`k_1` is set to 0, assuming no shrinkage in the first session. Again, :math:`\boldsymbol{b}^*` is mean-subtracted via

.. math::

    \boldsymbol{b}^* = \boldsymbol{b}^* - \text{mean}(\boldsymbol{k}^*\bar{d}+\boldsymbol{b}^*)

, where

.. math::

    \bar{d} = \frac{1}{N_p}\sum_{i}^{N_p}d^i.

Instead of using a direct readout of probe position, as in the rigid case, the probe position :math:`p^i(d)` at depth :math:`d` in session :math:`i` can be computed as

.. math::

    p^i(d) = k^*_id + b^*_i.

Then, the :ref:`waveform correction <waveform_correction_label>` step proceeds similarly to the rigid case. The corrected waveform :math:`\tilde{\mathbf{W}}` for unit :math:`i` on the reference probe is

.. math::

    \tilde{\mathbf{W}^i}(\boldsymbol{v}_\mathcal{C}) = K(\boldsymbol{v_\mathcal{C}} - \{0, \boldsymbol{p}_{
    \boldsymbol{s}_i}
    \},\boldsymbol{v_\mathcal{C}})K(\boldsymbol{v_\mathcal{C}},\boldsymbol{v_\mathcal{C}})^{-1}\mathbf{W}_\mathcal{C}^i,

where :math:`\boldsymbol{p}_{\boldsymbol{s}_i}` is now computed as

.. math::

    \boldsymbol{p}_{\boldsymbol{s}_i} = k^*_{\boldsymbol{s}_i}y^i + b^*_{\boldsymbol{s}_i}.

Although nonlinear effects exist and the cause of non-rigid motion is not fully clear, this method can better correct probe motion. Non-rigid correction should be used carefully, because it can become unstable for low-quality datasets due to overfitting. See :ref:`here <non_rigid_correction_setting_label>` for how to turn non-rigid motion correction on or off in ``settings.json``.

The comparison below shows the clustering results with and without non-rigid correction.

**Rigid**:

.. image:: ./images/OverviewRigid.png
   :width: 100%
   :align: center

**Non-rigid**:

.. image:: ./images/OverviewNonRigid.png
   :width: 100%
   :align: center

.. image:: ./images/MotionNonRigid.png
   :width: 60%
   :align: center   

Although these two methods found similar mean probe motion across sessions, non-rigid correction revealed inconsistent motion between the top and bottom regions of the probe, which in turn helped recover many more matches across sessions.


References
------------

.. [1] Steinmetz, Nicholas A., Cagatay Aydin, Anna Lebedeva, Michael Okun, Marius Pachitariu, Marius Bauza, Maxime Beau, et al. “Neuropixels 2.0: A Miniaturized High-Density Probe for Stable, Long-Term Brain Recordings.” Science 372, no. 6539 (April 16, 2021): eabf4588. https://doi.org/10.1126/science.abf4588.

.. [2] Boussard, Julien, Erdem Varol, Hyun Dong Lee, Nishchal Dethe, and Liam Paninski. “Three-Dimensional Spike Localization and Improved Motion Correction for Neuropixels Recordings.” In Advances in Neural Information Processing Systems, 34:22095-105. Curran Associates, Inc., 2021. https://proceedings.neurips.cc/paper/2021/hash/b950ea26ca12daae142bd74dba4427c8-Abstract.html.

