#!/bin/bash


#SBATCH --partition=imghmemq
#SBATCH --qos=img
# This specifies type of node job will use 

#SBATCH --nodes=1

# This specifies job uses 1 node

#SBATCH --ntasks-per-node=1

# This specifies job only use 1 core on the node

#SBATCH --mem=5g

# This specifies maximum memory use will be 5 gigabytes

#SBATCH --time=1:00:00

# This specifies job will last no longer than 1 hour

#below use Linux commands, which will run on compute node

#module load freesurfer-img/7.1.0
#module load fsl-img/6.0.3
#module load afni-uon/binary/21.0.20
#module load python-img/gcc6.3.0/3.7.2
#module load R-img/gcc6.3.0/3.6.1
module load pyspfm-uon/gcc11.3.0/0.0.1b7

#for R_LIBS in abind lars MASS snow wavethresh
#do
#	export R_LIBS=/gpfs01/home/lpxmh2/R-extra:${R_LIBS}
#done
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
if [[ -z "${HRF}" ]]; then
  HRF=spm
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

CRITERIA_LC=$(echo "${CRITERIA}" | tr '[:upper:]' '[:lower:]')
PREFIX=$(echo ${CRITERIA}_${HRF})

cd ${PRJDIR}/Data/01_PreprocData/${SBJID%%_*}/${SBJID##*_}
MASK=$(echo ${SBJID}_mask_MNI.nii.gz)
echo $(pwd)

# Run MESPFM
echo "Running MEPFM"
echo "pySPFM ${INPUT} -mask ${MASK} -R2only -criteria ${CRITERIA_LC} -hrf ${HRF} -maxiterfactor ${MAXITERFACTOR} -jobs ${JOBS} -prefix ${PREFIX}"

pySPFM -i ${SBJID}_echo01_spc.nii.gz ${SBJID}_echo02_spc.nii.gz ${SBJID}_echo03_spc.nii.gz -te ${TE} -tr ${TR} -m ${MASK} -crit 'stability' -hrf ${HRF} --max_iter_factor ${MAXITERFACTOR} -jobs ${JOBS} -o ${PREFIX}

# move to D03_Preprocessed folder if analysis was done in whole-brain dataset (i.e. no slice given)
# otherwise 3dZcat and mv are done with S10_MEPFM_MergeAllModels_OneSubjectOneRun_BCBL
# =================================================================================================
# create output directory for statistics data
if [[ ! -d "${PRJDIR}/Data/02_Statistics/${SBJID%%_*}/${SBJID##*_}" ]]; then
    echo "Creating folder ${PRJDIR}/Data/02_Statistics/${SBJID%%_*}/${SBJID##*_}" 
    mkdir "${PRJDIR}/Data/02_Statistics/${SBJID%%_*}/${SBJID##*_}"
else
    echo "Folder ${PRJDIR}/Data/02_Statistics/${SBJID%%_*}/${SBJID##*_} already exists. Will overwrite existing datasets."
fi

echo -e "\033[0;32m#====================================#\033[0m"
echo -e "\033[0;32m#  SUCCESSFUL TERMINATION OF SCRIPT  #\033[0m"
echo -e "\033[0;32m#====================================#\033[0m"
