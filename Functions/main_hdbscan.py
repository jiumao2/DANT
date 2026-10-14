import argparse
import numpy as np
import json
import os
import scipy
import hdbscan

parser = argparse.ArgumentParser() 
parser.add_argument('json_filename', help='the name of json file')  
args = parser.parse_args()  

if args.json_filename:
    settings = json.load(open(args.json_filename))

data_folder = settings['data_folder']

distance_matrix = np.load(os.path.join(data_folder, 'DistanceMatrix.npy'))

mdl = hdbscan.HDBSCAN(
    min_cluster_size=settings['min_cluster_size'],
    metric=settings['metric'],
    max_cluster_size=settings['max_cluster_size'],
    min_samples=settings['min_samples'],
    cluster_selection_epsilon=settings['cluster_selection_epsilon']
)

if 'unit_shanks_file' in settings:
    shanks = np.load(os.path.join(data_folder, settings['unit_shanks_file'])).ravel()
    idx = np.full(len(shanks), -1, dtype=np.int64)
    offset = 0
    for shank in np.unique(shanks):
        units = np.flatnonzero(shanks == shank)
        if len(units) < 2:
            continue
        labels = mdl.fit_predict(distance_matrix[np.ix_(units, units)])
        matched = labels >= 0
        idx[units[matched]] = labels[matched] + offset
        if np.any(matched):
            offset += int(labels[matched].max()) + 1
else:
    idx = mdl.fit_predict(distance_matrix)
np.save(os.path.join(data_folder, 'ClusterIndices.npy'), idx)

if 'unit_shanks_file' not in settings:
    Z = mdl.single_linkage_tree_.to_numpy()
    Z_matlab = scipy.cluster.hierarchy.to_mlab_linkage(Z)
    np.save(os.path.join(data_folder, 'LinkageMatrix.npy'), Z_matlab)

