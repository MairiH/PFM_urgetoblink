#!/bin/bash


#SBATCH --partition=imghmemq
#SBATCH --qos=img
# This specifies type of node job will use 

#SBATCH --nodes=1

# This specifies job uses 1 node

#SBATCH --ntasks-per-node=1

# This specifies job only use 1 core on the node

#SBATCH --mem=10g

# This specifies maximum memory use will be 5 gigabytes

#SBATCH --time=2:00:00

# This specifies job will last no longer than 1 hour

#below use Linux commands, which will run on compute node

#module load freesurfer-img/7.1.0
#module load fsl-img/6.0.3
module load afni-uon/binary/21.0.20
#module load python-img/gcc6.3.0/3.7.2
#module load R-img/gcc6.3.0/3.6.1

for R_LIBS in abind lars MASS snow wavethresh
do
	export R_LIBS=/gpfs01/home/lpxmh2/R-extra:${R_LIBS}
done
################################################################################
##########   Script for each subject and run ###################################
################################################################################

# READ INPUT PARAMETERS
# =====================
PRJDIR=$1
SBJID=$2

# CHECK INPUT VARIABLES REQUIRED
# ========================
if [[ -z "${PRJDIR}" ]]; then
        echo "You need to provide PRJDIR as FIRST INPUT variable"
        exit
fi
if [[ -z "${SBJID}" ]]; then
        echo "You need to provide SBJID as SECOND INPUT variable"
        exit
fi
if [[ -z ${CRITERIA} ]]; then
  CRITERIA=BIC
fi
if [[ -z "${RHO}" ]]; then
  RHO=0
fi
if [[ -z "${HRF}" ]]; then
  HRF=SPMG1
fi
if [[ -z "${JOBS}" ]]; then
  JOBS=1
fi
if [[ -z "${MAXITERFACTOR}" ]]; then
  MAXITERFACTOR=1
fi
if [[ -z "${ECHOES}" ]]; then
  ECHOES=(`cat ${PRJDIR}/Blink_Data/${SBJID%%_*}/${SBJID::-6}_echoes.1D`)
fi

set -e

echo "PRJDIR=${PRJDIR}"
echo "SBJ=${SBJID}"

DIR_3dMEPFM="/gpfs01/share/TS-SPFM/my_afni"


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

# create output directory for preprocessed data
if [[ ! -d "${PRJDIR}/Data/01_PreprocData/${SBJID%%_*}/${SBJID##*_}" ]]; then
    echo "Creating folder ${PRJDIR}/Data/01_PreprocData/${SBJID%%_*}/${SBJID##*_}" 
    mkdir ${PRJDIR}/Data/01_PreprocData/${SBJID%%_*}/${SBJID##*_}
else
    echo "Folder ${PRJDIR}/Data/01_PreprocData/${SBJID%%_*}/${SBJID##*_} already exists. Will overwrite existing datasets."
fi

# Compute Number of Echoes
# ========================
echo -e "\033[0;32m++ INFO: Echoes = ${ECHOES}\033[0m"
ECHOES=(`echo ${ECHOES} | tr -s ',' ' '`)
echo -e "\033[0;32m++ INFO: Echoes = ${ECHOES[@]}\033[0m"
Ne=$(echo ${#ECHOES[@]})
echo -e "\033[0;32m++ INFO: Number of Available Echoes = ${Ne}\033[0m"

# Shuffle
cd ${PRJDIR}/Data/01_PreprocData/${SBJID%%_*}/${SBJID##*_}/DTMP
# MASK=$(echo ${SBJID}_mask_MNI_sl${SLICE}.nii.gz)
# cd ${PRJDIR}/Data/01_PreprocData/${SBJID%%_*}/${SBJID##*_}
# echo "Shuffling"
# ${DIR_3dMEPFM}/3dFFTshuffle -input ${SBJID}_echo01_spc_sl${SLICE}.nii.gz -input ${SBJID}_echo02_spc_sl${SLICE}.nii.gz -input ${SBJID}_echo03_spc_sl${SLICE}.nii.gz -equal -mask ${MASK} -prefix EqualShuffle -jobs 1
# cd ${PRJDIR}/Blink_Data/

# Create Input Parameters
# =======================
INPUT_PARS=''
for e in $(seq 1 "$Ne")
do
    EID=$(printf %02d $e)
    E_IDX=$(echo "${e}-1" | bc -l)
    TE=$(echo "scale=4; ${ECHOES[${E_IDX}]}/1000;" | bc -l)
    # if [[ -z "${SLICE}" ]]; then
    # INPUT=$(echo ${PRJDIR}/Data/01_PreprocData/${SBJID%%_*}/${SBJID##*_}/${SBJID}_echo${EID}_spc.nii.gz)
    # else
    INPUT=$(echo EqualShuffle_${SBJID}_echo${EID}_spc_sl${SLICE}.nii.gz)
    # fi
    INPUT_PARS=$(echo ${INPUT_PARS} -input ${INPUT} ${TE})
    TR=$(3dinfo -TR ${INPUT})
done

CRITERIA_LC=$(echo "${CRITERIA}" | tr '[:upper:]' '[:lower:]')
PREFIX=$(echo ${CRITERIA}_${HRF})

cd ${PRJDIR}/Data/01_PreprocData/${SBJID%%_*}/${SBJID##*_}/DTMP
MASK=$(echo ${SBJID}_mask_MNI_sl${SLICE}.nii.gz)
echo $(pwd)



# Run MESPFM
echo "Running shuffled MEPFM"
echo "${DIR_3dMEPFM}/3dMEPFM ${INPUT_PARS} -mask ${MASK} -R2only -criteria ${CRITERIA_LC} -hrf ${HRF} -maxiterfactor ${MAXITERFACTOR} -jobs ${JOBS} -prefix ${PREFIX}"

${DIR_3dMEPFM}/3dMEPFM ${INPUT_PARS} -mask ${MASK} -R2only -criteria ${CRITERIA_LC} -hrf ${HRF} -maxiterfactor ${MAXITERFACTOR} -jobs ${JOBS} -prefix ${PREFIX}

# move to D03_Preprocessed folder if analysis was done in whole-brain dataset (i.e. no slice given)
# otherwise 3dZcat and mv are done with S10_MEPFM_MergeAllModels_OneSubjectOneRun_BCBL
# =================================================================================================
# create output directory for statistics data
# if [[ ! -d "${PRJDIR}/Data/02_Statistics/${SBJID%%_*}/${SBJID##*_}" ]]; then
#    echo "Creating folder ${PRJDIR}/Data/02_Statistics/${SBJID%%_*}/${SBJID##*_}" 
#    mkdir "${PRJDIR}/Data/02_Statistics/${SBJID%%_*}/${SBJID##*_}"
# else
#    echo "Folder ${PRJDIR}/Data/02_Statistics/${SBJID%%_*}/${SBJID##*_} already exists. Will overwrite existing datasets."
# fi

# if [[ "${MODEL}" == *"R2ONLY"* ]]; then
# DATAS=("DR2" "sigmas_MAD" "costs" "lambda")
# else
#     DATAS=(DR2 DS0 sigmas_MAD costs lambda)
# fi

# echo "${DATAS}"
# for DATA in "${DATAS[@]}"
# do
  # we need to refit datatype and -TR (this is due to a bug in the way AFNI copies the header with R functions)
  # 3drefit -'epan' -TR "${TR}" ${DATA}_${PREFIX}_${SBJID}_*
  # mv -f "${SBJID}_${PREFIX}.${DATA}*" "${PRJDIR}/Data/02_Statistics/${SBJID%%_*}/${SBJID##*_}/."
# done   #DATA
# 3drefit -'epan' -TR "${TR}" ${SBJID}_${PREFIX}.dr2HRF_E01*
# mv -f "${SBJID}_${PREFIX}.dr2HRF_E01*" "${PRJDIR}/Data/02_Statistics/${SBJID%%_*}/${SBJID##*_}/."
# 3drefit -'epan' -TR "${TR}" ${SBJID}_${PREFIX}.dr2HRF_E02*
# mv -f "${SBJID}_${PREFIX}.dr2HRF_E02*" "${PRJDIR}/Data/02_Statistics/${SBJID%%_*}/${SBJID##*_}/."
# 3drefit -'epan' -TR "${TR}" ${SBJID}_${PREFIX}.dr2HRF_E03*
# mv -f "${SBJID}_${PREFIX}.dr2HRF_E03*" "${PRJDIR}/Data/02_Statistics/${SBJID%%_*}/${SBJID##*_}/."


echo -e "\033[0;32m#====================================#\033[0m"
echo -e "\033[0;32m#  SUCCESSFUL TERMINATION OF SCRIPT  #\033[0m"
echo -e "\033[0;32m#====================================#\033[0m"
