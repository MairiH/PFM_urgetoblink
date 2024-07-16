import os
import sys
from pdb import set_trace as bp

import matplotlib.pyplot as plt
import numpy as np
from connPFM.connectivity.connectivity_utils import calculate_ets
from nilearn.masking import apply_mask

N_MASKS = 23
N_SAMPLES = 202
MASKS_DIR = "/mnt/d/Experiments/Experiment2-Blink_Tic/SPFM/Subregion_masks"
WHOLE_MASKS_DIR = "/mnt/d/Experiments/Experiment2-Blink_Tic/SPFM/Masks"


def calculate_rss(data):
    #  Calculate ETS
    ets = calculate_ets(data, data.shape[1])[0]

    #  Calculate RSS
    rss = np.sqrt(np.sum(np.square(ets), axis=1))

    # Calculate RSS with only positive ETS
    ets_pos = ets.copy()
    ets_pos[ets_pos < 0] = 0
    rss_pos = np.sqrt(np.sum(np.square(ets_pos), axis=1))

    # Calculate RSS with only negative ETS
    ets_neg = ets.copy()
    ets_neg[ets_neg > 0] = 0
    rss_neg = np.sqrt(np.sum(np.square(ets_neg), axis=1))

    return rss, rss_pos, rss_neg


def _main():

    #  Get data directory as first CLI argument
    dr2_file = sys.argv[1]

    data_dir = os.path.dirname(dr2_file)

    # Get list of files in current directory
    files = os.listdir(MASKS_DIR)

    #  Extract files that have "Ins", "17Networks" and "3mm" in their name
    mask_files_ins = [f for f in files if "Ins" in f and "17Networks" in f]

    #  Concatenate the two lists
    mask_files = mask_files_ins

    # Initialize matrix of zeros of size (n_samples, n_masks)
    data = np.zeros((N_SAMPLES, N_MASKS))

    # Loop through mask files
    for mask_file in mask_files:
        print(f"Loading data in {mask_file}...")
        # Apply mask to data
        data[:, mask_files.index(mask_file)] = np.mean(
            apply_mask(dr2_file, os.path.join(MASKS_DIR, mask_file)), axis=1
        )

    #  Calculate ETS and RSS
    print("Calculating ETS and RSS...")
    rss, rss_pos, rss_neg = calculate_rss(data)

    print(f"Saving RSS to {data_dir}...")

    sub = dr2_file[dr2_file.find("Sub") : dr2_file.find("Sub") + 5]
    run = dr2_file[dr2_file.find("run") : dr2_file.find("run") + 5]

    #  Save RSS to 1D file
    np.savetxt(os.path.join(data_dir, f"{sub}_{run}_rss_thesis.1D"), rss)
    np.savetxt(os.path.join(data_dir, f"{sub}_{run}_rss_pos_thesis.1D"), rss_pos)
    np.savetxt(os.path.join(data_dir, f"{sub}_{run}_rss_neg_thesis.1D"), rss_neg)

    print("End of script!")


if __name__ == "__main__":
    _main()
