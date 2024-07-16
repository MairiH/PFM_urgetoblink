import argparse
import csv
import os
import sys
import os.path as op
from re import L

import numpy as np
from MH_consensus_utils import consensus_kmeans
from nilearn.input_data import NiftiMasker
from nilearn.masking import unmask
from sklearn.cluster import KMeans
from sklearn.metrics import pairwise_distances


PRJDIR = "/mnt/h/Experiments/Experiment2-Blink_Tic/SPFM/02_Statistics"

def _get_parser():
    parser = argparse.ArgumentParser()
    optional = parser._action_groups.pop()

    # Optional arguments
    optional.add_argument(
        "-o",
        "--out",
        help="Name of the output CSV file without the extension.",
        dest="output",
        default="consensus_clusters",
        type=str,
    )
    optional.add_argument(
        "-k",
        "--k_selection",
        help="Criterion to select k.",
        type=str,
        default="iCAPs",
        choices=["iCAPs", "AUC"],  # "AUC_grad"],
        dest="k_selection",
    )
    optional.add_argument(
        "--kmax",
        help="Give a maximum number of clusters.",
        type=float,
        default=15,
        dest="kmax",
    )
    optional.add_argument(
        "--sampling",
        help="Percentage of subjects to use for k-means consensus clustering.",
        type=float,
        default=0.8,
        dest="sampling",
    )

    parser._action_groups.append(optional)

    return parser

def consensus_clustering(
    k_selection="iCAPs",
    kmax=15,
    sampling=0.8,
    output="consensus_clusters"
):
    # Turn kmax into integer
    if kmax < 1:
        kmax = int(np.ceil(kmax))
    elif kmax > 1:
        kmax = int(kmax)
    else:
        raise ValueError("kmax should be below or over 1.")

    k_range = np.arange(2, kmax)   

    #  Create output directory if it does not exist
    output_dir = os.path.join(PRJDIR, output)
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    #  Create masker
    masker = NiftiMasker(mask_img=os.path.join(PRJDIR, "dr2_peaks_median_Num_mask_no_thr.nii.gz"))
    dr2_peaks = masker.fit_transform(os.path.join(PRJDIR, "dr2_peaks_higher_than_median_NUM.nii.gz"))
    p_distance = pairwise_distances(dr2_peaks, metric='euclidean')

    # Initialize CDF, AUC and iCAPS_cons
    CDF = np.zeros((len(k_range), 100))
    AUC = np.zeros((len(k_range)))
    iCAPS_cons = np.zeros((len(k_range)))


    # Perform k-means clustering on 100 subsamples of the data and a range of k
    # values to find consensus at each TR.
 
    print(f"Performing k-means clustering...")
    # Perform k-means clustering in parallel
    results = [consensus_kmeans(p_distance, k, sampling) for k in k_range]

    CDF = np.stack([result[0] for result in results], axis=0)
    AUC = np.array([result[1] for result in results])
    iCAPS_cons = np.array([result[2] for result in results])

    # Select the best k value for each TR
    if k_selection == "iCAPs":
        k_idx = np.argmax(iCAPS_cons)
    elif k_selection == "AUC":
        k_idx = np.argmax(AUC)


    # Write the results to a csv
    print("Writing results to CSV file...")
    with open(op.join(PRJDIR, f"{output_dir}.csv"), "w") as f:
        writer = csv.writer(f)
        writer.writerow(["k", "CDF", "AUC", "iCAPS_cons"])
        writer.writerow(
            [
                k_range[k_idx],
                np.mean(CDF),
                AUC,
                iCAPS_cons,
            ]
        )
    f.close()

def _main(argv=None):
    options = _get_parser().parse_args(argv)
    consensus_clustering(**vars(options))


if __name__ == "__main__":
    _main()
