import os
import sys
from pdb import set_trace as bp

import numpy as np
from nilearn.input_data import NiftiMasker
from sklearn.cluster import KMeans

PRJDIR = "/mnt/h/Experiments/Experiment2-Blink_Tic/SPFM/02_Statistics"

def _main():


    # Get output directory from CLI argument
    output_dir = os.path.join(PRJDIR, sys.argv[1])

    #  Create output directory if it does not exist
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    #  Read dr2_peaks.npy
    dr2_peaks = np.load(os.path.join(PRJDIR, "dr2_peaks_higher_than_median_NUM.npy"))

    #  Create masker
    masker = NiftiMasker(mask_img=os.path.join(PRJDIR, "MNI_mask.nii.gz"))
    masker.fit_transform(os.path.join(PRJDIR, "MNI152_T1_3mm_brain.nii.gz"))


    # Get mean dr2 value in MNI space
    dr2_mni = masker.inverse_transform(dr2_peaks)

    # Save mean dr2 cluster
    dr2_mni.to_filename(os.path.join(output_dir, "dr2_peaks_higher_than_median_NUM.nii.gz"))

    #3dcalc -a dr2_peaks_higher_than_median_NUM.nii.gz -expr 'bool(a)' -prefix dr2_peaks_median_bool_NUM.nii.gz
    #3dTstat -sum -prefix dr2_peaks_median_bool_sum_NUM.nii.gz dr2_peaks_median_bool_NUM.nii.gz
    #3dcalc -a dr2_peaks_median_bool_sum_NUM.nii.gz -expr 'astep(a,100)' -prefix dr2_peaks_median_NUM_mask.nii.gz


if __name__ == "__main__":
    _main()