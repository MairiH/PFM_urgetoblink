import os
from pdb import set_trace as bp

import numpy as np
from nilearn.masking import apply_mask
from scipy.signal import find_peaks

PRJDIR = "/mnt/d/Experiments/Experiment2-Blink_Tic/SPFM/02_Statistics"


def _main():

    # Read list_subject_run_ALL.txt into list
    with open(os.path.join(PRJDIR, "list_subject_runs_ALL.txt"), "r") as f:
        list_subject_run_ALL = f.read().splitlines()
    num_peaks = []
    # Loop through list
    for idx, subject_run in enumerate(list_subject_run_ALL):

        # Split subject_run into subject and run
        sbj, run = subject_run.split("_")

        # Data directory
        data_dir = os.path.join(PRJDIR, sbj, run)

        # Get Ins ATS files
        ats_ins_file = os.path.join(
            data_dir, f"ATSnum_neg.THC_beta_{sbj}_{run}_BIC_SPMG1.DR2_4D_clust_Ins.1D"
        )
        ats_ins_shuff_file = os.path.join(
            data_dir, f"ATSnum_neg.THC_beta_{sbj}_{run}_BIC_SPMG1_EqualShuffle.DR2_4D_clust_Ins.1D"
        )

        #  Read DR2 data with mask
        dr2_file = os.path.join(data_dir, f"THC_beta_{sbj}_{run}_BIC_SPMG1.DR2_4D_clust.nii.gz")
        mask_file = os.path.join(PRJDIR, f"MNI_mask.nii.gz")
        dr2_masked = apply_mask(dr2_file, mask_file)

        #  Check if file exists
        if os.path.isfile(ats_ins_file):

            #  Read ATS file
            ats_ins = np.loadtxt(ats_ins_file)
            ats_ins_shuff = np.loadtxt(ats_ins_shuff_file)

            # Set first and last 16 points to zero to account for 'Random' condition
            # ats_ins[:16] = 0
            # ats_ins[-16:] = 0

            # Find the median of the ats_ins_shuff data
            ats_ins_shuff_median = np.median(ats_ins_shuff)

            # Find the index where ats_ins is higher than ats_ins_shuff_median
            idx_ins = np.nonzero(ats_ins > ats_ins_shuff_median)[0]

            # Loop through idx_match
            for idx_ins_idx in idx_ins:
                if idx_ins_idx == 0:
                    dr2_selection = dr2_masked[idx_ins_idx : idx_ins_idx + 1, :]
                    dr2_selection_sum = np.sign(dr2_selection[0, :]) * np.sum(
                    abs(dr2_selection), axis=0
                )
                else:
                    dr2_selection = dr2_masked[idx_ins_idx - 1 : idx_ins_idx + 1, :]
                    dr2_selection_sum = np.sign(dr2_selection[1, :]) * np.sum(
                        abs(dr2_selection), axis=0
                    )

                # Get data on selected peaks
                if idx == 0: 
                    dr2_peaks = dr2_selection_sum
                else:
                    dr2_peaks = np.vstack((dr2_peaks, dr2_selection_sum))
                

            # Create array with idx_match and previous and next values
            # idx_match_array = np.array([idx_match, idx_match - 1, idx_match + 1])
            # idx_match_array = idx_match_array.reshape(-1)

            # print(f"Selected {len(idx_match_array)} peaks for subject {sbj} run {run}")
            print(f"Selected {len(idx_ins)} peaks for subject {sbj} run {run}")
            print(idx_ins)
            num_peaks = np.hstack((num_peaks, idx_ins))

    # Save peaks matrix into npy file
    #np.save(os.path.join(PRJDIR, "dr2_peaks_higher_than_median_NUM.npy"), dr2_peaks)
    #np.savetxt(os.path.join(PRJDIR, "num_peaks.csv"), num_peaks,delimiter="\t")

if __name__ == "__main__":
    _main()
