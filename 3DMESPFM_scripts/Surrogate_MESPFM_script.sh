PRJDIR=/gpfs01/share/TS-SPFM
echo "Working directory: ${PRJDIR}"
# subject ID
# LIST_SBJID=$(cat list_subject_runs.txt)
LIST_SBJID="Sub01_run01"
set -e

# ==================================================
# PREPARING FOR ME-SPFM (Detrending and Signal Percentage Change)
# ==================================================
# for SBJID in ${LIST_SBJID}
# do
#     if [[ -e  ${PRJDIR}/LogFiles/preproc_${SBJID}_shuff ]]; then
#         echo "Deleting ${PRJDIR}/LogFiles/preproc_${SBJID}_shuff"
#         rm ${PRJDIR}/LogFiles/preproc_${SBJID}_shuff
#     fi 
#     echo "Submitting preprocessing job for ${SBJID}"
#     sbatch --partition=imgcomputeq --qos=img --nodes=1 --ntasks-per-node=1 --mem=100g --time=0:10:00 --job-name=${SBJID}_preproc_shuff -o ${PRJDIR}/LogFiles/preproc_${SBJID}_shuff -e ${PRJDIR}/LogFiles/preproc_${SBJID}_shuff ${PRJDIR}/3dMEPFM_scripts/01_preprocessing_shuffle_After_CSF_CompCor.sh ${PRJDIR} ${SBJID}
# done


# ==================================================
# Split into Slices for running 3dMEPFM parallelization
# ==================================================
# for SBJID in ${LIST_SBJID}
# do
#     if [[ -e  ${PRJDIR}/LogFiles/3dZcutup_${SBJID}_shuff ]]; then
#         echo "Deleting ${PRJDIR}/LogFiles/3dZcutup_${SBJID}_shuff"
#         rm ${PRJDIR}/LogFiles/3dZcutup_${SBJID}_shuff
#     fi 
#     echo "Submitting preprocessing job for ${SBJID}"
#     sbatch --partition=imgcomputeq --qos=img --nodes=1 --ntasks-per-node=1 --mem=10g --time=1:00:00 --job-name=${SBJID}_3dZcutup_shuff -o ${PRJDIR}/LogFiles/3dZcutup_${SBJID}_shuff -e ${PRJDIR}/LogFiles/3dZcutup_${SBJID}_shuff ${PRJDIR}/3dMEPFM_scripts/02_Shuffle_and_slice.sh ${PRJDIR} ${SBJID}
# done

# ===========================================================
# ME-SPFM R2ONLY and MEICA-R2ONLY
# ===========================================================
# for SBJID in ${LIST_SBJID}
# do
#     cd ${PRJDIR}/Data/01_PreprocData/${SBJID%%_*}/${SBJID##*_}
#     NK=$(3dinfo -nk ${SBJID}_mask_MNI.nii.gz)
#     NK=$(echo "$NK -1" | bc)
#     SLICES=$(count -digits 2 0 $NK)
#     HRFMODEL=SPMG1
#     for ii in $SLICES
#     do
#         for MODEL in R2ONLY #MEICA-R2ONLY GLASSO MEICA-GLASSO
#         do
#             echo "Submitting ME-SPFM ${MODEL} job for subject ${SBJID%%_*} run ${SBJID##*_} hrf ${HRFMODEL} slice ${ii} SHUFFLED"
#             if [[ -e "${PRJDIR}/LogFiles/MESPFM_${MODEL}_${SBJID%%_*}_${SBJID##*_}_${HRFMODEL}_sl${ii}_shuffle" ]]; then
#                 rm ${PRJDIR}/LogFiles/MESPFM_${MODEL}_${SBJID%%_*}_${SBJID##*_}_${HRFMODEL}_sl${ii}_shuffle
#             fi
#             # Select RHO
#             if [[ ${MODEL} == *"R2S0"* ]]; then
#                 RHO=0.5
#             elif [[ ${MODEL} == *"GLASSO"* ]]; then
#                 RHO=0
#             else
#                 RHO=0 # Default value
#             fi
#             sbatch --partition=imghmemq --qos=img --nodes=1 --ntasks-per-node=1 --mem=10g --time=2:00:00 --job-name=${SBJ}_${RUN}_sl${ii}_MESPFM_${MODEL}_shuffle --export MODEL=${MODEL},RHO=${RHO},CRITERIA=BIC,JOBS=10,SLICE=${ii},HRF=${HRFMODEL} -o ${PRJDIR}/LogFiles/MESPFM_${MODEL}_${HRFMODEL}_${SBJID}_sl${ii}_shuffle -e ${PRJDIR}/LogFiles/MESPFM_${MODEL}_${SBJID%%_*}_${SBJID##*_}_${HRFMODEL}_sl${ii}_shuffle ${PRJDIR}/3dMEPFM_scripts/03_run_MESPFM_surrogate.sh ${PRJDIR} ${SBJID}
#         done # MODEL
#     done # SLICES
# done # SBJ

# ==================================================
# Concatenate Slices of 3dMEPFM results
# ==================================================
 for SBJID in ${LIST_SBJID}
 do
     if [[ -e  ${PRJDIR}/LogFiles/3dZcat_${SBJID}_shuffle ]]; then
         echo "Deleting ${PRJDIR}/LogFiles/3dZcat_${SBJID}_shuffle"
         rm ${PRJDIR}/LogFiles/3dZcat_${SBJID}_shuffle
     fi 
     echo "Submitting preprocessing job for ${SBJID}"
     sbatch --partition=imghmemq --qos=img --nodes=1 --ntasks-per-node=1 --mem=4g --time=1:00:00 --job-name=${SBJID}_3dZcat_shuffle -o ${PRJDIR}/LogFiles/3dZcat_${SBJID}_shuffle -e ${PRJDIR}/LogFiles/3dZcat_${SBJID}_shuffle ${PRJDIR}/3dMEPFM_scripts/04_ConcatenateSlices_surrogate.sh ${PRJDIR} ${SBJID} BIC_SPMG1_EqualShuffle
 done


echo -e "\033[0;32m#====================================#\033[0m"
echo -e "\033[0;32m#  SUCCESSFUL TERMINATION OF SCRIPT  #\033[0m"
echo -e "\033[0;32m#====================================#\033[0m"
