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
#     if [[ -e  ${PRJDIR}/LogFiles/preproc_${SBJID} ]]; then
#         echo "Deleting ${PRJDIR}/LogFiles/preproc_${SBJID}"
#         rm ${PRJDIR}/LogFiles/preproc_${SBJID}
#     fi 
#     echo "Submitting preprocessing job for ${SBJID}"
#     sbatch --partition=imghmemq --qos=img --nodes=1 --ntasks-per-node=1 --mem=4g --time=1:00:00 --job-name=${SBJID}_preproc -o ${PRJDIR}/LogFiles/preproc_${SBJID} -e ${PRJDIR}/LogFiles/preproc_${SBJID} ${PRJDIR}/3dMEPFM_scripts/01_preprocessing_After_CSF_CompCor.sh ${PRJDIR} ${SBJID}
# done

# ==================================================
# Split into Slices for running 3dMEPFM parallelization
# ==================================================
# for SBJID in ${LIST_SBJID}
# do
#     if [[ -e  ${PRJDIR}/LogFiles/3dZcutup_${SBJID} ]]; then
#         echo "Deleting ${PRJDIR}/LogFiles/3dZcutup_${SBJID}"
#         rm ${PRJDIR}/LogFiles/3dZcutup_${SBJID}
#     fi 
#     echo "Submitting preprocessing job for ${SBJID}"
#     sbatch --partition=imghmemq --qos=img --nodes=1 --ntasks-per-node=1 --mem=4g --time=1:00:00 --job-name=${SBJID}_3dZcutup -o ${PRJDIR}/LogFiles/3dZcutup_${SBJID} -e ${PRJDIR}/LogFiles/3dZcutup_${SBJID} ${PRJDIR}/3dMEPFM_scripts/02_PreSliceDataForParalelization.sh ${PRJDIR} ${SBJID}
# done


# ===========================================================
# ME-SPFM R2ONLY and MEICA-R2ONLY
# ===========================================================
 for SBJID in ${LIST_SBJID}
 do
     cd ${PRJDIR}/Data/01_PreprocData/${SBJID%%_*}/${SBJID##*_}
     NK=$(3dinfo -nk ${SBJID}_mask_MNI.nii.gz)
     NK=$(echo "$NK -1" | bc)
     HRFMODEL=spm
     echo "Submitting pySPFM job for subject ${SBJID%%_*} run ${SBJID##*_} hrf ${HRFMODEL}"
     if [[ -e "${PRJDIR}/LogFiles/pySPFM_${SBJID%%_*}_${SBJID##*_}_${HRFMODEL}" ]]; then
         rm ${PRJDIR}/LogFiles/pySPFM_${SBJID%%_*}_${SBJID##*_}_${HRFMODEL}             
     fi
     cd ${PRJDIR}/Blink_Data/
     CRDIR=$(pwd)
     echo ${CRDIR} 
             
     # find compute the optimal order of Legendre polynomials to remove trends above 120 seconds
     NT=$(3dinfo -nt "${CRDIR}/${SBJID%%_*}/${SBJID##*_}/${SBJID}_echo01.feat/filtered_func_data_MNI.nii.gz")
     echo "Number of volumes = ${NT}"
     TR=$(3dinfo -tr "${CRDIR}/${SBJID%%_*}/${SBJID##*_}/${SBJID}_echo01.feat/filtered_func_data_MNI.nii.gz")
     echo "TR = ${TR}"
     POLORTORDER=$(echo "1 + (${TR}*${NT})/120" | bc)
     echo "Detrending Will use ${POLORTORDER} Legendre polynomials"
             
     # Compute Number of Echoes
     # ========================
     ECHOES=(`cat ${PRJDIR}/Blink_Data/${SBJID%%_*}/${SBJID::-6}_echoes.1D`)
     echo -e "\033[0;32m++ INFO: Echoes = ${ECHOES}\033[0m"
     ECHOES=(`echo ${ECHOES} | tr -s ',' ' '`)
     echo -e "\033[0;32m++ INFO: Echoes = ${ECHOES[@]}\033[0m"
     Ne=$(echo ${#ECHOES[@]})
     echo -e "\033[0;32m++ INFO: Number of Available Echoes = ${Ne}\033[0m"
             
     # Create Input Parameters
     # =======================
     INPUT=$(echo ${SBJID}_spc.nii.gz)
             
     sbatch --partition=imghmemq --qos=img --nodes=1 --ntasks-per-node=1 --mem=5g --time=20:00:00 --job-name=${SBJ}_${RUN}_pySPFM --export JOBS=100,HRF=${HRFMODEL},INPUT=${INPUT},TE=${ECHOES},TR=${TR} -o ${PRJDIR}/LogFiles/pySPFM_${HRFMODEL}_${SBJID} -e ${PRJDIR}/LogFiles/pySPFM_${SBJID%%_*}_${SBJID##*_}_${HRFMODEL} ${PRJDIR}/3dMEPFM_scripts/03_run_pySPFM.sh ${PRJDIR} ${SBJID}
 done

# ==================================================
# Concatenate Slices of 3dMEPFM results
# ==================================================
# for SBJID in ${LIST_SBJID}
# do
#     if [[ -e  ${PRJDIR}/LogFiles/3dZcat_${SBJID} ]]; then
#         echo "Deleting ${PRJDIR}/LogFiles/3dZcat_${SBJID}"
#         rm ${PRJDIR}/LogFiles/3dZcat_${SBJID}
#     fi 
#     echo "Submitting preprocessing job for ${SBJID}"
#     sbatch --partition=imgcomputeq --qos=img --nodes=1 --ntasks-per-node=1 --mem=4g --time=1:00:00 --job-name=${SBJID}_3dZcat -o ${PRJDIR}/LogFiles/3dZcat_${SBJID} -e ${PRJDIR}/LogFiles/3dZcat_${SBJID} ${PRJDIR}/3dMEPFM_scripts/04_ConcatenateSlices.sh ${PRJDIR} ${SBJID} BIC_SPMG1
# done


echo -e "\033[0;32m#====================================#\033[0m"
echo -e "\033[0;32m#  SUCCESSFUL TERMINATION OF SCRIPT  #\033[0m"
echo -e "\033[0;32m#====================================#\033[0m"
