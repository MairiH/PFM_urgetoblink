#!/bin/bash


#SBATCH --partition=imgcomputeq
#SBATCH --qos=img
# This specifies type of node job will use 

#SBATCH --nodes=1

# This specifies job uses 1 node

#SBATCH --ntasks-per-node=1

# This specifies job only use 1 core on the node

#SBATCH --mem=10g

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

DIR_3dMEPFM="/gpfs01/share/TS-SPFM/my_afni"

cd ${PRJDIR}/Blink_Data/
CRDIR=$(pwd)
echo ${CRDIR} 

# # find compute the optimal order of Legendre polynomials to remove trends above 120 seconds
# NT=$(3dinfo -nt "${CRDIR}/${SBJID%%_*}/${SBJID##*_}/${SBJID}_echo01.feat/filtered_func_data_MNI.nii.gz")
# echo "Number of volumes = ${NT}"
# TR=$(3dinfo -tr "${CRDIR}/${SBJID%%_*}/${SBJID##*_}/${SBJID}_echo01.feat/filtered_func_data_MNI.nii.gz")
# echo "Number of volumes = ${TR}"
# POLORTORDER=$(echo "1 + (${TR}*${NT})/120" | bc)
# echo "Detrending Will use ${POLORTORDER} Legendre polynomials"

cd ${PRJDIR}/Data/01_PreprocData/${SBJID%%_*}/${SBJID##*_}/ 
MASK=$(echo ${SBJID}_mask_MNI.nii.gz)

for ECHO in 01 02 03
do
    3dTcat ${PRJDIR}/Data/01_PreprocData/${SBJID%%_*}/${SBJID##*_}/${SBJID}_echo${ECHO}_dt.nii.gz[16..217] -output ${PRJDIR}/Data/01_PreprocData/${SBJID%%_*}/${SBJID##*_}/${SBJID}_echo${ECHO}_dt_crop.nii.gz -overwrite
done

echo "Computing shuffled dataset for echo ${ECHO} of ${SBJID} "
${DIR_3dMEPFM}/3dFFTshuffle -input ${SBJID}_echo01_dt_crop.nii.gz -input ${SBJID}_echo02_dt_crop.nii.gz -input ${SBJID}_echo03_dt_crop.nii.gz -equal -mask ${MASK} -prefix EqualShuffle -jobs 1
for ECHO in 01 02 03
do
    cd ${CRDIR}/${SBJID%%_*}/${SBJID##*_}/${SBJID}_echo${ECHO}.feat/
	echo "Computing signal percentage change of EqualShuffle detrended echo ${ECHO} of ${SBJID} "
    3dTstat -mean -prefix rm.${SBJID}_echo${ECHO}_mean.nii.gz ${PRJDIR}/Data/01_PreprocData/${SBJID%%_*}/${SBJID##*_}/EqualShuffle_${SBJID}_echo${ECHO}_dt_crop.nii.gz -overwrite
    3dcalc -a ${PRJDIR}/Data/01_PreprocData/${SBJID%%_*}/${SBJID##*_}/EqualShuffle_${SBJID}_echo${ECHO}_dt_crop.nii.gz -b rm.${SBJID}_echo${ECHO}_mean.nii.gz -expr '(a-b)/b' \
            -prefix ${PRJDIR}/Data/01_PreprocData/${SBJID%%_*}/${SBJID##*_}/EqualShuffle_${SBJID}_echo${ECHO}_dt_spc.nii.gz -overwrite
			
	echo "Deleting temporary files"
    rm rm.*.nii.gz
done

#cd ${PRJDIR}/Data/01_PreprocData/${SBJID%%_*}/${SBJID##*_}/ 
#${DIR_3dMEPFM}/3dFFTshuffle -input ${SBJID}_echo01_spc.nii.gz -input ${SBJID}_echo02_spc.nii.gz -input ${SBJID}_echo03_spc.nii.gz -equal -mask ${MASK} -prefix EqualShuffle -jobs 1
 
#for ECHO in 01 02 03
#do
#
#    echo "Computing temporal statistics of detrended echo ${ECHO} of ${SBJID}"
#    3dTstat -stdevNOD -mask ${MASK} -prefix std_${SBJID}_echo${ECHO}_dt.nii.gz ${SBJID}_echo${ECHO}_dt.nii.gz -overwrite
#    3dTstat -mean -mask ${MASK} -prefix mean_${SBJID}_echo${ECHO}_dt.nii.gz ${SBJID}_echo${ECHO}_dt.nii.gz -overwrite
#    3dTstat -sos -mask ${MASK} -prefix sos_${SBJID}_echo${ECHO}_dt.nii.gz ${SBJID}_echo${ECHO}_dt.nii.gz -overwrite
#
#    echo "Computing temporal statistics of EqualShuffle detrended echo ${ECHO} of ${SBJID} "
#    3dTstat -stdevNOD -prefix std_EqualShuffle_${SBJID}_echo${ECHO}_dt.nii.gz EqualShuffle_${SBJID}_echo${ECHO}_dt.nii.gz -overwrite
#    3dTstat -mean -prefix mean_EqualShuffle_${SBJID}_echo${ECHO}_dt.nii.gz EqualShuffle_${SBJID}_echo${ECHO}_dt.nii.gz -overwrite
#    3dTstat -sos -prefix sos_EqualShuffle_${SBJID}_echo${ECHO}_dt.nii.gz EqualShuffle_${SBJID}_echo${ECHO}_dt.nii.gz -overwrite
#
#    echo "Computing temporal statistics of SPC echo ${ECHO} of ${SBJID} "
#    3dTstat -stdevNOD -mask ${MASK} -prefix std_${SBJID}_echo${ECHO}_spc.nii.gz ${SBJID}_echo${ECHO}_spc.nii.gz -overwrite
#    3dTstat -mean -mask ${MASK} -prefix mean_${SBJID}_echo${ECHO}_spc.nii.gz ${SBJID}_echo${ECHO}_spc.nii.gz -overwrite
#    3dTstat -sos -mask ${MASK} -prefix sos_${SBJID}_echo${ECHO}_spc.nii.gz ${SBJID}_echo${ECHO}_spc.nii.gz -overwrite
#
#    echo "Computing temporal statistics of EqualShuffle detrended and spc echo ${ECHO} of ${SBJID} "
#    3dTstat -stdevNOD -prefix std_EqualShuffle_${SBJID}_echo${ECHO}_dt_spc.nii.gz EqualShuffle_${SBJID}_echo${ECHO}_dt_spc.nii.gz -overwrite
#    3dTstat -mean -prefix mean_EqualShuffle_${SBJID}_echo${ECHO}_dt_spc.nii.gz EqualShuffle_${SBJID}_echo${ECHO}_dt_spc.nii.gz -overwrite
#    3dTstat -sos -prefix sos_EqualShuffle_${SBJID}_echo${ECHO}_dt_spc.nii.gz EqualShuffle_${SBJID}_echo${ECHO}_dt_spc.nii.gz -overwrite
#
#    echo "Computing temporal statistics of EqualShuffle of SPC echo ${ECHO} of ${SBJID} "
#    3dTstat -stdevNOD -prefix std_EqualShuffle_${SBJID}_echo${ECHO}_spc.nii.gz EqualShuffle_${SBJID}_echo${ECHO}_spc.nii.gz -overwrite
#    3dTstat -mean -prefix mean_EqualShuffle_${SBJID}_echo${ECHO}_spc.nii.gz EqualShuffle_${SBJID}_echo${ECHO}_spc.nii.gz -overwrite
#    3dTstat -sos -prefix sos_EqualShuffle_${SBJID}_echo${ECHO}_spc.nii.gz EqualShuffle_${SBJID}_echo${ECHO}_spc.nii.gz -overwrite
#
#done 






echo -e "\033[0;32m#====================================#\033[0m"
echo -e "\033[0;32m#  SUCCESSFUL TERMINATION OF SCRIPT  #\033[0m"
echo -e "\033[0;32m#====================================#\033[0m"
