import random

import numpy as np
import pandas as pd
from scipy.cluster.hierarchy import leaves_list, linkage, optimal_leaf_ordering
from sklearn.cluster import KMeans


def sub2ind(array_shape, rows, cols):
    ind = rows * array_shape[1] + cols
    ind[ind < 0] = -1
    ind[ind >= array_shape[0] * array_shape[1]] = -1
    return ind


def compute_connectivity_matrix(n_points, labels):
    M = np.zeros([n_points, n_points])
    for j in range(n_points):
        if labels[j] > 0:
            m = np.where(labels == labels[j])
            M[j, m] = 1
    return M


def cluster_quality(Consensus):
    aux = np.triu(np.ones(Consensus.shape), 1)
    indexes = np.where(aux != 0)
    values = Consensus[indexes]
    c = np.round(np.linspace(0, 1, 100), 2)
    CDF = np.zeros(100)
    for i in range(100):
        CDF[i] = np.count_nonzero(values <= c[i]) / len(values)
    AUC = np.dot(np.diff(c), CDF[1:])
    return CDF, AUC


def getClusterConsensus(IDX, Consensus):
    nClus = int(np.max(IDX))
    iCAPs_consensus = np.zeros([nClus, 1])
    iCAPs_nItems = np.zeros([nClus, 1])
    Consensus_re = Consensus.reshape(Consensus.shape[0] * Consensus.shape[1])
    for iC in range(1, nClus + 1):
        clusID = [i for i, x in enumerate(list(IDX)) if x == iC]
        len(clusID)
        # ID of the sub-consensus matrix of cluster iC
        rowID = np.tile(clusID, [len(clusID), 1])
        rowID = rowID.reshape(len(clusID) * len(clusID), 1)[:, 0]
        colID = np.repeat(clusID, len(clusID))
        matID = sub2ind(Consensus.shape, rowID, colID)
        iCAPs_consensus[iC - 1, 0] = np.mean(np.mean(Consensus_re[matID]))
        iCAPs_nItems[iC - 1, 0] = len(clusID)
    return iCAPs_consensus, iCAPs_nItems


def consensus_kmeans(data, k, sampling):

    n_points = data.shape[0]
    KM = KMeans(n_clusters=k, random_state=123)
    M_sum = np.zeros([n_points, n_points])
    I_sum = np.zeros([n_points, n_points])

    for i in range(100):
        selected_idxs = np.sort(random.sample(range(n_points), int(np.ceil(n_points * sampling))))
        I = pd.DataFrame([0] * n_points)
        I[0][selected_idxs] = 1
        I_sum = I_sum + np.dot(I, np.transpose(I))
        sparse_cluster = data[selected_idxs, :][:, selected_idxs]
        idx = KM.fit_predict(sparse_cluster) + 1
        idx = np.transpose(
            pd.DataFrame([idx, selected_idxs])
        )  # Create a vector that combines the previous indexes and the labels
        idx = idx.set_index(1)
        labels = np.array([0] * n_points)
        labels[selected_idxs] = idx[0]
        M = compute_connectivity_matrix(n_points, labels)
        M_sum = M_sum + M
    Consensus = np.divide(M_sum, I_sum)
    Tree = linkage(Consensus, method="average", optimal_ordering=True)
    # dendrogram(Tree)
    order = leaves_list(optimal_leaf_ordering(Tree, Consensus))
    Consensus_ordered = Consensus[order, :][:, order]
    CDF, AUC = cluster_quality(Consensus_ordered)
    IDX = KM.fit_predict(sparse_cluster) + 1
    iCAPS_cons, _ = getClusterConsensus(IDX, Consensus_ordered)
    print(f"Indices for k={k} are {IDX}")

    return CDF, AUC, np.mean(iCAPS_cons)
