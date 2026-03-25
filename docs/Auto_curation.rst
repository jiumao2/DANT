Auto curation
===================

Auto curation is the last step in the pipeline. It helps refine the clustering results and control the false positive rate. It includes two steps:

(1) Removal of units from the same session within a cluster.

(2) Splitting of clusters based on the LDA-derived threshold.

Step 1: Removal of units from the same session
-------------------------------------------------------------------

.. image:: images/AutoCurationA.png
    :width: 100%
    :align: center

|

HDBSCAN assumes that units within a cluster originate from distinct sessions (``max_cluster_size`` = number of sessions; see :ref:`Clustering <HDBSCAN_label>`), so we need to keep that assumption valid. However, clustering results can sometimes violate this assumption, so a cluster may end up containing units from the same session (left panel). To address this, we remove the units with the lowest mean similarity to the other units in the cluster (right panel), which keeps the cluster cleaner and more consistent. This step ensures that each cluster contains only one unit per session. The number of matched pairs removed in this step ranges from 1% to 10%.

.. _auto_curation_step2_label:

Step 2: Splitting of clusters based on the LDA-derived threshold
-------------------------------------------------------------------
.. image:: images/AutoCurationB.png
    :width: 100%
    :align: center

|

Although the density-based clustering algorithm finds relatively "dense" clusters, it does not guarantee that all units within a cluster are truly similar enough to each other. We use the LDA-derived similarity threshold to cleanly separate these cases. As shown in the left panel, some units are similar to each other (solid lines, similarity >= threshold), while others are not (dashed lines). This forms an undirected graph, and our goal is to find its connected components, in other words, groups of units connected by solid lines. In this example, we find two connected components (right panel). The original cluster b is now split into two subclusters (cluster c and cluster d).

Step 2 curation is optional and can be skipped by editing ``settings.json`` (see :ref:`Change default settings <auto_split_label>`). In practice, this step usually removes very few matched pairs. In most datasets, it removes less than 1% of matched pairs.
