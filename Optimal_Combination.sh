#!/bin/bash

# Get list of subjects and runs from list_subject_runs_ALL.txt
# sub_runs=$(cat list_subject_runs_ALL.txt)
sub_runs="Sub15_run03"
cwd=/mnt/h/Experiments/Experiment2-Blink_Tic/SPFM/01_PreprocData

# Loop through all subjects and runs
for sub_run in ${sub_runs}; do

    # Get subject and run
    SBJ=$(echo "$sub_run" | cut -d "_" -f 1)
    run=$(echo "$sub_run" | cut -d "_" -f 2)
	
    fdir="${cwd}/${SBJ}/${run}"
    edir="/mnt/h/Experiments/Experiment2-Blink_Tic/SPFM/Echo_times"
    @compute_OC_weights -echo_times_file ${edir}/${SBJ}_echoes.1D \
        -echo_dsets ${fdir}/${sub_runs}_echo*_dt.nii.gz \
        -prefix OCweights_${sub_runs}

    3dMean -weightset OCweights_${sub_runs}+tlrc -prefix opt.combined \
    ${fdir}/${sub_runs}_echo01_dt.nii.gz ${fdir}/${sub_runs}_echo02_dt.nii.gz ${fdir}/${sub_runs}_echo03_dt.nii.gz
    
    3dAFNItoNIFTI -prefix "/mnt/h/Experiments/Experiment2-Blink_Tic/conv/OC_${sub_runs}" opt.combined+tlrc
    rm OCweights_${sub_runs}*
    rm opt.combined*
    rm -r OC.weight.results
done