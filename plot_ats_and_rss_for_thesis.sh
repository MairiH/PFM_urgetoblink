#!/bin/bash

# Get list of subjects and runs from list_subject_runs_ALL.txt
#sub_runs=$(cat list_subject_runs_ALL.txt)
sub_runs="Sub17_run03"
# Get current directory
prj_dir=$(pwd)

# Loop through all subjects and runs
for sub_run in ${sub_runs}; do

    # Get subject and run
    sub=$(echo "$sub_run" | cut -d "_" -f 1)
    run=$(echo "$sub_run" | cut -d "_" -f 2)

    # Move to subject and run directory
    cd "$prj_dir"/"$sub"/"$run" || exit

    echo "Calculating RSS of ${sub}_${run}..."
    # Calculate RSS
    python3 "$prj_dir"/calculate_rss_for_thesis.py THC_beta_"${sub}"_"${run}"_BIC_SPMG1.DR2_4D_clust.nii.gz

    echo "Plotting ATS of ${sub}_${run}..."
    # Plot ATS
    python3 "$prj_dir"/plots_for_thesis.py

    # Move back to project directory
    cd "$prj_dir" || exit

done

echo "End of script!"
