FAQ
===

.. contents::
    :local:

.. _manual_motion_label:

How do I manually set motion?
-----------------------------

DANT and pyDANT can use a user-provided probe motion file instead of starting motion correction from zero. This is useful when you want to provide your own motion estimate, either from another method or from manual inspection and correction of a DANT result that is clearly wrong.

A typical manual workflow is to run DANT once, inspect ``Figures/Overview.png`` together with ``Output.Motion`` or ``Motion.mat``, manually adjust the motion values when the estimated motion is clearly wrong, save the adjusted motion as ``motion.npy``, set ``waveformCorrection.path_to_motion``, and rerun with ``"Waveform"`` included in the first motion-correction feature set.

Prepare a NumPy ``.npy`` file, for example ``motion.npy``. Motion values should be in μm, and the order must match session indices ``1, 2, ..., n_session``.

For rigid motion, save one value per session:

.. code-block:: python

    import numpy as np

    motion = np.array([0.0, 12.5, -8.0])
    np.save("motion.npy", motion)

For non-rigid motion, save a ``2 x n_session`` array. The first row is the linear term and the second row is the constant term:

.. code-block:: python

    import numpy as np

    linear = np.array([0.0, 1.2, -0.8])
    constant = np.array([0.0, 12.5, -8.0])
    motion = np.vstack([linear, constant])
    np.save("motion.npy", motion)

For non-rigid motion, DANT and pyDANT compute the session-specific correction at each unit depth as:

.. math::

    \mathrm{motion} = 0.001 \times \mathrm{linear}_{\mathrm{session}} \times \mathrm{depth}_{\mu m} + \mathrm{constant}_{\mathrm{session}}

If you have already run MATLAB DANT once, you can create ``motion.npy`` directly from ``Output.Motion`` in ``DANT_Output/Output.mat``. This is the preferred source because it stores the final motion used for the output.

For rigid motion, export ``Output.Motion.Constant``:

.. code-block:: matlab

    load('DANT_Output/Output.mat', 'Output');

    motion = Output.Motion.Constant;  % rigid motion, 1 x n_session, in um
    writeNPY(motion, 'motion.npy');

You can also manually edit specific sessions before saving:

.. code-block:: matlab

    load('DANT_Output/Output.mat', 'Output');

    motion = Output.Motion.Constant;
    motion(3) = 25;  % manually adjust session 3, in um
    writeNPY(motion, 'motion.npy');

For non-rigid motion, export both the linear and constant terms:

.. code-block:: matlab

    load('DANT_Output/Output.mat', 'Output');

    motion = [Output.Motion.Linear; Output.Motion.Constant];
    writeNPY(motion, 'motion.npy');

Then set ``waveformCorrection.path_to_motion`` in ``settings.json``:

.. code-block:: json

    "waveformCorrection": {
        "n_nearest_channels": 38,
        "linear_correction": false,
        "n_templates": 2,
        "path_to_motion": "path/to/motion.npy"
    }

When ``path_to_motion`` is set, the first motion-correction feature set must include ``"Waveform"``:

.. code-block:: json

    "motionEstimation": {
        "features": [
            ["Waveform", "AutoCorr", "PETH"],
            ["Waveform", "AutoCorr", "PETH"]
        ]
    }

This requirement is important because the manually provided motion is applied by correcting waveforms. If the first round uses only temporal features such as ``["AutoCorr", "PETH"]``, the first clustering round does not use the manually corrected waveforms, and the manually provided motion can be overwritten by the next automatic motion estimate.

If you do not want to manually set motion, leave ``path_to_motion`` as an empty string:

.. code-block:: json

    "path_to_motion": ""
