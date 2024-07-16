#!/bin/bash


#SBATCH --partition=imgcomputeq
#SBATCH --qos=img
# This specifies type of node job will use 

#SBATCH --nodes=1

# This specifies job uses 1 node

#SBATCH --ntasks-per-node=1

# This specifies job only use 1 core on the node

#SBATCH --mem=1g

# This specifies maximum memory use will be 4 gigabytes

#SBATCH --time=0:10:00

# This specifies job will last no longer than 1 hour

#below use Linux commands, which will run on compute node


# module load freesurfer-img/7.1.0
# module load fsl-img/6.0.3
module load afni-uon/binary/21.0.20
# module load python-img/gcc6.3.0/3.7.2


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

cd ${PRJDIR}/Blink_Data/
CRDIR=$(pwd)
echo ${CRDIR} 

# find compute the optimal order of Legendre polynomials to remove trends above 120 seconds
NT=$(3dinfo -nt "${CRDIR}/${SBJID%%_*}/${SBJID##*_}/${SBJID}_echo01.feat/filtered_func_data_MNI.nii.gz")
echo "Number of volumes = ${NT}"
TR=$(3dinfo -tr "${CRDIR}/${SBJID%%_*}/${SBJID##*_}/${SBJID}_echo01.feat/filtered_func_data_MNI.nii.gz")
echo "Number of volumes = ${TR}"
POLORTORDER=$(echo "1 + (${TR}*${NT})/120" | bc)
echo "Detrending Will use ${POLORTORDER} Legendre polynomials"

# create output directory for preprocessed data
if [[ ! -d "${PRJDIR}/Data/01_PreprocData/${SBJID%%_*}/${SBJID##*_}" ]]; then
    echo "Creating folder ${PRJDIR}/Data/01_PreprocData/${SBJID%%_*}/${SBJID##*_}" 
    mkdir ${PRJDIR}/Data/01_PreprocData/${SBJID%%_*}/${SBJID##*_}
else
    echo "Folder ${PRJDIR}/Data/01_PreprocData/${SBJID%%_*}/${SBJID##*_} already exists. Will overwrite existing datasets."
fi

for ECHO in 01 02 03
do
    cd ${CRDIR}/${SBJID%%_*}/${SBJID##*_}/${SBJID}_echo${ECHO}.feat/
    echo "Detrending echo ${ECHO} of ${SBJID}"
    3dDetrend -polort ${POLORTORDER} -vector "${CRDIR}/${SBJID%%_*}/${SBJID##*_}/PC_CSF_vec.1D" -prefix rm.${SBJID}_echo${ECHO}_dt.nii.gz filtered_func_data_MNI.nii.gz -overwrite
    echo "Computing mean of echo ${ECHO} of ${SBJID}"
    3dTstat -mean -prefix rm.${SBJID}_echo${ECHO}_mean.nii.gz filtered_func_data_MNI.nii.gz -overwrite
    echo "Computing signal percentage change of echo ${ECHO} of ${SBJID} "
    3dcalc -a rm.${SBJID}_echo${ECHO}_dt.nii.gz -b rm.${SBJID}_echo${ECHO}_mean.nii.gz -expr 'a+b' \
            -prefix ${PRJDIR}/Data/01_PreprocData/${SBJID%%_*}/${SBJID##*_}/${SBJID}_echo${ECHO}_dt.nii.gz -overwrite
    3dcalc -a rm.${SBJID}_echo${ECHO}_dt.nii.gz -b rm.${SBJID}_echo${ECHO}_mean.nii.gz -expr 'a/b' \
            -prefix ${PRJDIR}/Data/01_PreprocData/${SBJID%%_*}/${SBJID##*_}/${SBJID}_echo${ECHO}_spc.nii.gz -overwrite
    3dTcat ${PRJDIR}/Data/01_PreprocData/${SBJID%%_*}/${SBJID##*_}/${SBJID}_echo${ECHO}_spc.nii.gz[16..217] -output ${PRJDIR}/Data/01_PreprocData/${SBJID%%_*}/${SBJID##*_}/${SBJID}_echo${ECHO}_spc.nii.gz -overwrite
    echo "Deleting temporary files"
    rm rm.*.nii.gz
done

# Create mask (FSL tends to create a bigger brain mask than necessary)
3dAutomask -prefix ${CRDIR}/${SBJID%%_*}/${SBJID##*_}/${SBJID}_echo01.feat/mask_MNI.nii.gz ${CRDIR}/${SBJID%%_*}/${SBJID##*_}/${SBJID}_echo01.feat/filtered_func_data_MNI.nii.gz -overwrite

echo "Creating brain mask (erosion 1 voxel)"
3dmask_tool -input ${CRDIR}/${SBJID%%_*}/${SBJID##*_}/${SBJID}_echo01.feat/mask_MNI.nii.gz -fill_holes -prefix ${PRJDIR}/Data/01_PreprocData/${SBJID%%_*}/${SBJID##*_}/${SBJID}_mask_MNI.nii.gz -overwrite

echo -e "\033[0;32m#====================================#\033[0m"
echo -e "\033[0;32m#  SUCCESSFUL TERMINATION OF SCRIPT  #\033[0m"
echo -e "\033[0;32m#====================================#\033[0m"
