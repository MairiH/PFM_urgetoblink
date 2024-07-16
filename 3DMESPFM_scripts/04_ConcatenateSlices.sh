#!/bin/bash


#SBATCH --partition=imgcomputeq
#SBATCH --qos=img
# This specifies type of node job will use 

#SBATCH --nodes=1

# This specifies job uses 1 node

#SBATCH --ntasks-per-node=1

# This specifies job only use 1 core on the node

#SBATCH --mem=4g

# This specifies maximum memory use will be 4 gigabytes

#SBATCH --time=1:00:00

# This specifies job will last no longer than 1 hour

#below use Linux commands, which will run on compute node

#module load freesurfer-img/7.1.0
#module load fsl-img/6.0.3
module load afni-uon/binary/21.0.20
#module load python-img/gcc6.3.0/3.7.2
#module load R-img/gcc6.3.0/3.6.1

date

# READ INPUT PARAMETERS
# =====================
PRJDIR=$1
SBJID=$2
PREFIX=$3

# INPUT VARIABLES REQUIRED
# ========================
if [[ -z "${PRJDIR}" ]]; then
        echo "You need to provide PRJDIR as FIRST INPUT variable"
        exit
fi
if [[ -z "${SBJID}" ]]; then
        echo "You need to provide SBJID as SECOND INPUT variable"
        exit
fi
if [[ -z "${PREFIX}" ]]; then
        echo "You need to provide PREFIX as THIRD INPUT variable"
        exit
fi
if [[ -z "${MODEL}" ]]; then
        echo "No MODEL given as INPUT variable. Assuming MODEL=PREFIX"
        MODEL=${PREFIX}
fi
set -e

# ENTER DIRECTORY WHERE RESULTS RESIDE
# ====================================
cd ${PRJDIR}/Data/01_PreprocData/${SBJID%%_*}/${SBJID##*_}/DTMP

# Compute the number of slices (e.g., number of parallel processes to run)
# ========================================================================
NK=$(3dinfo -nk ../${SBJID}_mask_MNI.nii.gz)
NK=$(echo "$NK -1" | bc)
SLICES=$(count -digits 2 0 $NK)
TR=$(3dinfo -tr "${PRJDIR}/Blink_Data/${SBJID%%_*}/${SBJID##*_}/${SBJID}_echo01.feat/filtered_func_data_MNI.nii.gz")

# Reconstruct Datasets from set of slices
# =======================================
# if [[ "${MODEL}" == *"R2ONLY"* ]]; then
DATAS=(DR2 sigmas_MAD costs lambda)
# else
#    DATAS=(DR2 DS0 sigmas_MAD costs lambda)
# fi

# Define prefix for output datasets
# ======================================
# if [[ "${MODEL}" == *"MEICA"* && "${PREFIX}" != *"MEICA"*  ]]; then
#   OUTPREFIX="MEICA_${PREFIX}"
# else
OUTPREFIX=${PREFIX}
# fi

# get prefix for datasets
for DATA in ${DATAS[@]}
do
  DATA_LIST=""
  # append name to data list
  for SLICE in ${SLICES}
  do
    # if [[ "${MODEL}" == *"MEICA"* ]]; then
    #   DATA_LIST=$(echo $DATA_LIST ${DATA}_${PREFIX}_pc08.${SBJID}_MEICA.E01.spc.sl${SLICE}+tlrc.)
    # else
    DATA_LIST=$(echo $DATA_LIST ${DATA}_${PREFIX}_${SBJID}_echo01_spc_sl${SLICE}.nii.gz)
    # fi
  done #SLICES
  echo -e "\033[0;32m++ INFO: Working on ${OUTPREFIX} - ${DATA}\033[0m"
  3dZcat -datum float -prefix ${SBJID}_${OUTPREFIX}.${DATA}.nii.gz ${DATA_LIST} -overwrite
  # mv -f ${SBJID}_${OUTPREFIX}.${DATA}* ${PRJDIR}/Data/02_Statistics/${SBJID%%_*}/${SBJID##*_}/.
  # DATA_LIST_TO_RM=`echo ${DATA_LIST} | sed 's/tlrc./tlrc.*/g'`
  # rm ${DATA_LIST_TO_RM}
done   #DATA

DATAS=("DR2" "sigmas_MAD" "costs" "lambda")
echo "${DATAS}"
for DATA in "${DATAS[@]}"
do
  # we need to refit datatype and -TR (this is due to a bug in the way AFNI copies the header with R functions)
  3drefit -'epan' -TR "${TR}" "${SBJID}_${OUTPREFIX}.${DATA}.nii.gz"
  mv -f "${SBJID}_${OUTPREFIX}.${DATA}.nii.gz" "${PRJDIR}/Data/02_Statistics/${SBJID%%_*}/${SBJID##*_}/."
done   #DATA

# PUT TOGETHER ALL RESULTS FOR HRF FITS
# =====================================
# PREFIX=`echo ${SBJID}_${CRITERIA}_N${NC}.${MODEL}`
DR2fit_TE1_LIST=""
DR2fit_TE2_LIST=""
DR2fit_TE3_LIST=""
# append names to data lists
for SLICE in $SLICES
do
  # if [[ "${MODEL}" == *"MEICA"* ]]; then
  #   DR2fit_TE1_LIST=$(echo $DR2fit_TE1_LIST DR2fit_${PREFIX}_pc08.${SBJID}_MEICA.E01.spc.sl$SLICE+tlrc.)
  #   DR2fit_TE2_LIST=$(echo $DR2fit_TE2_LIST DR2fit_${PREFIX}_pc08.${SBJID}_MEICA.E02.spc.sl$SLICE+tlrc.)
  #   DR2fit_TE3_LIST=$(echo $DR2fit_TE3_LIST DR2fit_${PREFIX}_pc08.${SBJID}_MEICA.E03.spc.sl$SLICE+tlrc.)
  # else
  DR2fit_TE1_LIST=$(echo $DR2fit_TE1_LIST DR2fit_${PREFIX}_${SBJID}_echo01_spc_sl$SLICE.nii.gz)
  DR2fit_TE2_LIST=$(echo $DR2fit_TE2_LIST DR2fit_${PREFIX}_${SBJID}_echo02_spc_sl$SLICE.nii.gz)
  DR2fit_TE3_LIST=$(echo $DR2fit_TE3_LIST DR2fit_${PREFIX}_${SBJID}_echo03_spc_sl$SLICE.nii.gz)
  # fi
done


echo -e "\033[0;32m++ INFO: Working on ${OUTPREFIX} - R2fit E01 \033[0m"
3dZcat -datum float -prefix ${SBJID}_${OUTPREFIX}.dr2HRF_E01.nii.gz ${DR2fit_TE1_LIST} -overwrite
# mv -f ${SBJID}_${OUTPREFIX}.dr2HRF_E01* ${PRJDIR}/Data/02_Statistics/${SBJID%%_*}/${SBJID##*_}/.
echo -e "\033[0;32m++ INFO: Working on ${OUTPREFIX} - R2fit E02\033[0m"
3dZcat -datum float -prefix ${SBJID}_${OUTPREFIX}.dr2HRF_E02.nii.gz ${DR2fit_TE2_LIST} -overwrite
# mv -f ${SBJID}_${OUTPREFIX}.dr2HRF_E02* ${PRJDIR}/Data/02_Statistics/${SBJID%%_*}/${SBJID##*_}/.
echo -e "\033[0;32m++ INFO: Working on ${OUTPREFIX} - R2fit E03\033[0m"
3dZcat -datum float -prefix ${SBJID}_${OUTPREFIX}.dr2HRF_E03.nii.gz ${DR2fit_TE3_LIST} -overwrite
# mv -f ${SBJID}_${OUTPREFIX}.dr2HRF_E03* ${PRJDIR}/Data/02_Statistics/${SBJID%%_*}/${SBJID##*_}/.
#DATA_LIST1=`echo ${DR2fit_TE1_LIST}  | sed 's/tlrc./tlrc.*/g'`
#DATA_LIST2=`echo ${DR2fit_TE2_LIST}  | sed 's/tlrc./tlrc.*/g'`
#DATA_LIST3=`echo ${DR2fit_TE3_LIST}  | sed 's/tlrc./tlrc.*/g'`
#rm ${DATA_LIST1} ${DATA_LIST2} ${DATA_LIST3}



3drefit -'epan' -TR "${TR}" "${SBJID}_${PREFIX}.dr2HRF_E01.nii.gz"
mv -f "${SBJID}_${OUTPREFIX}.dr2HRF_E01.nii.gz" "${PRJDIR}/Data/02_Statistics/${SBJID%%_*}/${SBJID##*_}/."
3drefit -'epan' -TR "${TR}" "${SBJID}_${PREFIX}.dr2HRF_E02.nii.gz"
mv -f "${SBJID}_${OUTPREFIX}.dr2HRF_E02.nii.gz" "${PRJDIR}/Data/02_Statistics/${SBJID%%_*}/${SBJID##*_}/."
3drefit -'epan' -TR "${TR}" "${SBJID}_${PREFIX}.dr2HRF_E03.nii.gz"
mv -f "${SBJID}_${OUTPREFIX}.dr2HRF_E03.nii.gz" "${PRJDIR}/Data/02_Statistics/${SBJID%%_*}/${SBJID##*_}/."


echo -e "\033[0;32m#====================================#\033[0m"
echo -e "\033[0;32m#  SUCCESSFUL TERMINATION OF SCRIPT  #\033[0m"
echo -e "\033[0;32m#====================================#\033[0m"
