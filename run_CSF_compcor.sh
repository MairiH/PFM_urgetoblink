#! /bin/bash

cwd=/mnt/h/Experiments/Experiment2-Blink_Tic/SPFM/Tedana/MaskOutputs/Reclassified
sdir=/mnt/h/Experiments/Experiment2-Blink_Tic/SPFM/02_Statistics/GrayPlots



for SBJ in Sub01 Sub03 Sub04 Sub05 Sub06 Sub07 Sub09 Sub10 Sub11 Sub12 Sub13 Sub14 Sub15 Sub16 Sub17 Sub18 Sub19 Sub20 Sub21 Sub22; 
do

    for run in run01 run02 run03; 
    do
    	sbjdir="${cwd}/${SBJ}_${run}"
    	fdir="${sbjdir}"
    	adir="/mnt/h/Experiments/Experiment2-Blink_Tic/SPFM/feat_preproc/${SBJ}_run01_echo01.feat/reg/Segsy"
    	seg="Classes"

        if [[ -d "$fdir" ]]
        then

    	    cd "$fdir" || exit

            echo "$run"

            echo "Compute CSF mask from T2star map"
            3dcalc -a "${fdir}/T2starmap.nii" -expr "step(a-0.1)" -prefix "${fdir}/rm.CSF.T2star.nii" -overwrite
            3dmask_tool -input "${fdir}/rm.CSF.T2star.nii" -fill_holes -prefix "${fdir}/rm.CSF.T2star.filled.nii" -overwrite


            # find compute the optimal order of Legendre polynomials to remove trends above 120 seconds
            NT=$(3dinfo -nt "${fdir}/desc-optcomDenoised_bold.nii.gz")
            echo "Number of volumes = ${NT}"
            TR=$(3dinfo -tr "${fdir}/desc-optcomDenoised_bold.nii.gz")
            echo "Number of volumes = ${TR}"
            POLORTORDER=$(echo "1 + (${TR}*${NT})/120" | bc)

            echo "Detrending of OC dataset will use ${POLORTORDER} Legendre polynomials"
            3dDetrend -polort ${POLORTORDER} -prefix "${fdir}/rm.desc-optcomDenoised_bold.dt.nii.gz" "${fdir}/desc-optcomDenoised_bold.nii.gz" -overwrite
           
            echo "Compute principal components of CSF voxels"
            3dpc -mask "${fdir}/rm.CSF.T2star.filled.nii" -pcsave 5 -prefix PC_CSF "${fdir}/rm.desc-optcomDenoised_bold.dt.nii.gz"

            rm rm.*

       fi
    done

    cd "${cwd}" || exit
done