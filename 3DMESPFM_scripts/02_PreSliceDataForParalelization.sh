#!/bin/bash


#SBATCH --partition=imgcomputeq
#SBATCH --qos=img
# This specifies type of node job will use 

#SBATCH --nodes=1

# This specifies job uses 1 node

#SBATCH --ntasks-per-node=1

# This specifies job only use 1 core on the node

#SBATCH --mem=1g

# This specifies maximum memory use will be 10 gigabytes

#SBATCH --time=0:20:00

# This specifies job will last no longer than 1 hour

#below use Linux commands, which will run on compute node

# module load freesurfer-img/7.1.0
# module load fsl-img/6.0.3
module load afni-uon/binary/21.0.20
# module load python-img/gcc6.3.0/3.7.2
#module load R-img/gcc6.3.0/3.6.1

################################################################################
##########   Script for each subject and run ###################################
################################################################################

# READ INPUT PARAMETERS
# =====================
PRJDIR=$1
SBJID=$2

echo "PRJDIR=${PRJDIR}"
echo "SBJ=${SBJID}"

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

set -e

cd ${PRJDIR}/Data/01_PreprocData/${SBJID%%_*}/${SBJID##*_}/ 
CRDIR=$(pwd)
echo ${CRDIR} 

# create output directory for preprocessed data
if [[ ! -d "${CRDIR}/DTMP" ]]; then
    echo "Creating folder ${CRDIR}/DTMP" 
    mkdir ${CRDIR}/DTMP
else
    echo "Folder ${CRDIR}/DTMP already exists. Will overwrite existing datasets."
fi

NK=$(3dinfo -nk ${SBJID}_mask_MNI.nii.gz)
NK=$(echo "$NK -1" | bc)
SLICES=$(count -digits 2 0 $NK)
echo "++ INFO: Max Number Slices = ${NK}"
for ii in $SLICES
do
    echo "++ 3dZcutup's of SLICE=${ii}/${NK}"
    3dZcutup -prefix ./DTMP/${SBJID}_mask_MNI_sl$ii.nii.gz -keep $ii $ii ${SBJID}_mask_MNI.nii.gz -overwrite
    3dZcutup -prefix ./DTMP/${SBJID}_echo01_spc_sl$ii.nii.gz -keep $ii $ii ${SBJID}_echo01_spc.nii.gz -overwrite
    3dZcutup -prefix ./DTMP/${SBJID}_echo02_spc_sl$ii.nii.gz -keep $ii $ii ${SBJID}_echo02_spc.nii.gz -overwrite
    3dZcutup -prefix ./DTMP/${SBJID}_echo03_spc_sl$ii.nii.gz -keep $ii $ii ${SBJID}_echo03_spc.nii.gz -overwrite
done

echo -e "\033[0;32m#====================================#\033[0m"
echo -e "\033[0;32m#  SUCCESSFUL TERMINATION OF SCRIPT  #\033[0m"
echo -e "\033[0;32m#====================================#\033[0m"
