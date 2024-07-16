#!/bin/bash

# Get list of subjects and runs from list_subject_runs_ALL.txt
sub_runs=$(cat list_subject_runs_ALL.txt)
# sub_runs='Sub01_run01'

# Get current directory
prj_dir=$(pwd)
LBL='4D_clust'
WIN=1
CSZ=10
THR=0

# Loop through all subjects and runs
for SBJID in ${sub_runs}
do
    cd "${prj_dir}"/"${SBJID%%_*}"/"${SBJID##*_}" || exit
    python /mnt/h/Experiments/Experiment2-Blink_Tic/SPFM/02_Statistics/stc.py --input "${SBJID}"_BIC_SPMG1.DR2.nii.gz --output "${SBJID}"_BIC_SPMG1.DR2_${LBL}.nii.gz --w_pos ${WIN} --w_neg ${WIN} --clustsize ${CSZ} --thr ${THR}
done
