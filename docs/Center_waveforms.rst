Center waveforms
=========================

.. image:: ./images/CenterWaveforms.png
   :width: 100%
   :align: center

|

Spike sorting algorithms like Kilosort may not perfectly center waveforms on the trough. This misalignment can significantly reduce waveform similarity and potentially affect DANT's performance. As shown in the figure above, two units from Kilosort, despite having intrinsically similar waveforms, show a Pearson correlation of only 0.29 when misaligned, compared with 0.89 when correctly centered.

To avoid this issue, we recommend centering waveforms before running DANT. If waveforms are not pre-centered, DANT can automatically align them to the trough on the peak channel. Keep in mind that this process involves cropping and nearest-neighbor extrapolation at the borders. It does not handle positive spikes well, so please make sure they are excluded when centering waveforms.

Refer to :ref:`Change default settings <centering_waveforms_setting_label>` for more details on how to configure waveform centering.











