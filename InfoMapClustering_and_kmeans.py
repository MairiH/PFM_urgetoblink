import os
import sys
from pdb import set_trace as bp

import infomap
import matplotlib
import networkx as nx

import numpy as np
from nilearn.input_data import NiftiMasker
from nilearn.masking import unmask
from sklearn.cluster import KMeans
from sklearn.metrics import pairwise_distances
# from sklearn.metrics.pairwise import pairwise_kernels

PRJDIR = "/mnt/h/Experiments/Experiment2-Blink_Tic/SPFM/02_Statistics"

def findCommunities(G):
    """
    Partition network with the Infomap algorithm.
    Annotates nodes with 'community' id and return number of communities found.
    """
    infomapX = infomap.Infomap("--two-level")

    print("Building Infomap network from a NetworkX graph...")
    for e in G.edges():
        infomapX.network.addLink(*e)

    print("Find communities with Infomap...")
    infomapX.run()

    print(
        "Found {} modules with codelength: {}".format(
            infomapX.numTopModules(), infomapX.codelength
        )
    )

    communities = {}
    for node in infomapX.iterLeafNodes():
        communities[node.physicalId] = node.moduleIndex()

    nx.set_node_attributes(G, values=communities, name="community")
    return communities


def _main(algorithm="infomap",n_init=None):
    # Get output directory from CLI argument
    output_dir = os.path.join(PRJDIR, sys.argv[1])

    algorithm = str(sys.argv[2]).lower()

    metric = str(sys.argv[3]).lower()

    if algorithm == 'kmeans':
        n_clusters = int(sys.argv[4])
        if n_init is None:
            n_init = 50
        else:
            n_init = int(sys.argv[5])
    
    #  Create output directory if it does not exist
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    #  Create masker
    masker = NiftiMasker(mask_img=os.path.join(PRJDIR, "dr2_peaks_median_NUM_mask_no_thr.nii.gz"))
    dr2_peaks = masker.fit_transform(os.path.join(PRJDIR, "dr2_peaks_higher_than_median_NUM.nii.gz"))

    #  Read dr2_peaks.npy
    # dr2_peaks = np.load(os.path.join(PRJDIR, "dr2_peaks.npy"))

    # Need to adapt metric depending on the algorithm 
    # Jaccard might be more appropriate for Infomap, 
    # whereas Euclidean might be better for K-means

    p_distance = pairwise_distances(dr2_peaks, metric=metric)
   
    import matplotlib.pyplot as plt
    plt.imshow(p_distance, aspect="auto", vmin=0, vmax=1, cmap="hot")
    plt.xlabel('Time-point')
    plt.ylabel('Time-point')
    plt.colorbar()
    plt.savefig(f"pdistance_{metric}.png")
    # plt.show()

    # make if to switch between algorithms
    if algorithm == "infomap":
        G = nx.from_numpy_matrix(p_distance)  # Again the binary
        coms = findCommunities(G)  # Clustering

        labels = np.zeros(p_distance.shape[0])
        for ii in coms:
            labels[ii] = coms[ii]

    elif algorithm == "kmeans":
        KM = KMeans(n_clusters=n_clusters,n_init=n_init)
        labels = KM.fit_predict(p_distance)

        # labels = np.transpose(
        #     pd.DataFrame([labels, indexes])
        # )  # Create a vector that combines the previous indexes and the labels
        # labels = labels.set_index(1)

        # final_labels = np.zeros(nscans)
        # # assign to each timepoint their label
        # for i in labels.index:
        #    final_labels[i] = labels[0][i] + 1

    #  Get labels
    np.savetxt(os.path.join(output_dir, "labels.1D"), labels)

    # For each label, get mean dr2 value
    for label in np.unique(labels):

        # Get dr2 values for label
        dr2_label = dr2_peaks[labels == label]

        # Get mean dr2 value
        mean_dr2 = np.mean(dr2_label, axis=0)

        # compute statistits of dr2 values (voxelwise mean/std) for each label
        std_dr2 = np.std(dr2_label, axis=0)
        z_dr2 = np.nan_to_num(mean_dr2/std_dr2)
        dr2_stats = np.vstack((mean_dr2,z_dr2))
        # save it
        dr2_stats_mni = unmask(dr2_stats,os.path.join(PRJDIR, "dr2_peaks_median_NUM_mask_no_thr.nii.gz"))
        dr2_stats_mni.to_filename(os.path.join(output_dir, f"Zframes_bucket_dr2_cluster_{label}.nii.gz"))

        # Z-normalization in space of the voxelwise z-statistics
        Zframes_dr2_z = (z_dr2 - np.mean(z_dr2)) / np.std(z_dr2)
        Z2frames_dr2_mni = masker.inverse_transform(Zframes_dr2_z)
        Z2frames_dr2_mni.to_filename(os.path.join(output_dir, f"Zframes_spatial_dr2_cluster_{label}.nii.gz"))

        # Z-normalization in space of the mean dr2 values
        mean_dr2_z = (mean_dr2 - np.mean(mean_dr2)) / np.std(mean_dr2)
        Zspatial_dr2_mni = masker.inverse_transform(mean_dr2_z)
        Zspatial_dr2_mni.to_filename(os.path.join(output_dir, f"Zspatial_dr2_cluster_{label}.nii.gz"))

        # Number of non-zero dr2 estimates in each voxel for each label
        num_dr2 = np.int32(np.count_nonzero(dr2_label,axis=0))
        num_dr2_bucket = dr2_stats = np.vstack((num_dr2,z_dr2))
        num_dr2_mni = masker.inverse_transform(num_dr2_bucket)
        num_dr2_mni.to_filename(os.path.join(output_dir, f"CountNonZero_dr2_cluster_{label}.nii.gz"))

if __name__ == "__main__":
    _main()
