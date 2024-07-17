# PFM_urgetoblink

First run segment_MRI.sh to segment the structural scan.
Next run run_CSF_compcor.sh to compute the prinicipal components of CSF voxels.
Then run the scripts in 3DMESPFM_scripts.
Next run 4D_clustering.sh or 4D_clustering_shuffled.sh to perform spatiotemporal clustering.
The run PFM_preproc_AFNI_custom_mask_1_MH_4Dclustered.sh (or .._Shuffled.sh) to calculate the signal percentage change.
Next run ATScalc_4Dclustered_WholeBrain_ClusterSorted.sh ( or ..._Shuffled_...sh to calculate the activation timeseries.
Then run peak_selection_higher_than_median.py to select peaks that had a higher number of activated voxels within the insula compared with the shuffled dataset.
Use dr2_peaks_npy_2_nii.py to convert the output into a nifti file.
Running plot_ats_and_rss_for_thesis.sh will plot the RSS and ATS.
MH_consensus_clustering.py is used to determine the ideal number of clusters k.
InfoMapClustering_and_kmeans.py can be used to perform k means clustering.
