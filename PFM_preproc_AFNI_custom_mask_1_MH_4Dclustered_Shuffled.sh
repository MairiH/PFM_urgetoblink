#! /bin/bash

# Created/Written by Cesar Caballero Gaudes @ BCBL.
# Amended and adapted by Hilmar P Sigurdsson - email: hpsig86@gmail.com
# @ Nottingham 2018
# Amended and adapted by Eneko Uruñuela and Mairi Houlgreave December 2021

PRJDIR=/mnt/h/Experiments/Experiment2-Blink_Tic/SPFM
MINBETA=0.01
CLUSTERSIZE=5
MYMASK=${PRJDIR}/Masks/RH_ins_3mm.nii.gz
ROIMASK='Ins'

LIST_SBJID=$(cat list_subject_runs_ALL.txt)
#LIST_SBJID='Sub01_run01'


CRDIR=$(pwd)
echo ${CRDIR} 


for SBJID in ${LIST_SBJID}
do

	#cd ${SBJID}
	echo -e "\033[1mThis is subject: ${SBJID%%_*}\033[0m"
	#echo "This is subject: ${sub_dir}"


	echo -e "\033[1mThis is run: ${SBJID##*_}\033[0m"

	cd ${CRDIR}/${SBJID%%_*}/${SBJID##*_}/
	pwd


	for DATASET in ${SBJID%%_*}_${SBJID##*_}_BIC_SPMG1_EqualShuffle.DR2_4D_clust.nii.gz #pc_filtered_func_data.nii.gz shuff_pc_filtered_func_data.nii.gz
	do
		for CRITERIA in bic #aic
		do

			
			if [ $MINBETA > 0 ]
				then
						# \\ Apply minimum amplitude thresholding in beta estimates from 3dPFM
					3dcalc -a ${DATASET} -expr "a*(1-astep(a,1))" -prefix THAmp_beta_${DATASET} -overwrite
						# \\ Apply minimum cluster size in beta estimates from 3dPFM

					3dcalc -a THAmp_beta_${DATASET} -expr 'posval(a)' -prefix pos_THAmp_beta_${DATASET} -overwrite
					3dcalc -a THAmp_beta_${DATASET} -expr 'posval(-1*a)' -prefix neg_THAmp_beta_${DATASET} -overwrite
					3dcalc -a neg_THAmp_beta_${DATASET} -expr "-1*a" -prefix neg_THAmp_beta_${DATASET} -overwrite
					3dmerge -dxyz=1 -1erode 50 -1clust 1 ${CLUSTERSIZE} -doall -prefix THC_beta_pos_${DATASET} pos_THAmp_beta_${DATASET} -overwrite
					3dmerge -dxyz=1 -1erode 50 -1clust 1 ${CLUSTERSIZE} -doall -prefix THC_beta_neg_${DATASET} neg_THAmp_beta_${DATASET} -overwrite
					3dcalc -a THC_beta_pos_${DATASET} -b THC_beta_neg_${DATASET} -expr "a+b" -prefix THC_beta_${DATASET} -overwrite
  					
					
				else
							# \\ Apply minimum cluster size in beta estimates from 3dPFM
					3dmerge -dxyz=1 -1clust 1 ${CLUSTERSIZE} -doall -prefix THC_beta_${DATASET:0:5}_EqualShuffle_4D_clust.nii.gz beta_${DATASET:0:5}_EqualShuffle_4D_clust.nii.gz -overwrite
			fi

				# \\ Define dataset for computation of ATS
			ATS_DATASET=THC_beta_${DATASET} #THAmp_beta_${PFX}_${DATASET:0:5}

			# \\ There are multiple possible definition for ATS (num, sum, power, etc). 
			# \\ I (Cesar) usually compute them in the beta, but you can also compute them on betafitts but I (Cesar) usually don't like it due to the HRF blurring

			#---- POSITIVE BETAS FOR DATASET 
			echo -e "\033[1mComputing Activation Time Series POSITIVE for ${DATASET}\033[0m"
 			3dcalc -a ${ATS_DATASET} -expr 'posval(a)' -prefix temp_pos -overwrite
  			3dcalc -a ${ATS_DATASET} -expr 'ispositive(a)' -prefix temp_pos_bool -overwrite
  				
				# \\ ROI mask (insula)
			3dmaskave -quiet -mask ${MYMASK} -sum temp_pos+tlrc. > ATSsum_pos.${ATS_DATASET:0:56}_${ROIMASK}.1D
			3dmaskave -quiet -mask ${MYMASK} -sum temp_pos_bool+tlrc. > ATSnum_pos.${ATS_DATASET:0:56}_${ROIMASK}.1D
  			rm temp_pos+tlrc.* temp_pos_bool+tlrc.*

  			# ---- NEGATIVE BETAS FOR DATASET
			echo -e "\033[1mComputing Activation Time Series NEGATIVE for ${DATASET}\033[0m"
  			3dcalc -a ${ATS_DATASET} -expr 'posval(-1*a)' -prefix temp_neg -overwrite
  			3dcalc -a ${ATS_DATASET} -expr 'ispositive(-1*a)' -prefix temp_neg_bool -overwrite
  				
  				# \\ ROI MASK (insula)
			3dmaskave -quiet -mask ${MYMASK} -sum temp_neg+tlrc. > ATSsum_neg.${ATS_DATASET:0:56}_${ROIMASK}.1D
			3dmaskave -quiet -mask ${MYMASK} -sum temp_neg_bool+tlrc. > ATSnum_neg.${ATS_DATASET:0:56}_${ROIMASK}.1D
  			rm temp_neg+tlrc.* temp_neg_bool+tlrc.*
  			
  			# ---- ABSOLUTE BETAS FOR DATASET
			echo -e "\033[1mComputing Activation Time Series ABSOLUTE for ${DATASET}\033[0m"
  			3dcalc -a ${ATS_DATASET} -expr 'abs(a)' -prefix temp_abs -overwrite
  			3dcalc -a ${ATS_DATASET} -expr 'bool(abs(a))' -prefix temp_abs_bool -overwrite
  				
				# \\ ROI MASK (insula)
			3dmaskave -quiet -mask ${MYMASK} -sum temp_abs+tlrc. > ATSsum_abs.${ATS_DATASET:0:56}_${ROIMASK}.1D
			3dmaskave -quiet -mask ${MYMASK} -sum temp_abs_bool+tlrc. > ATSnum_abs.${ATS_DATASET:0:56}_${ROIMASK}.1D
  			rm temp_abs+tlrc.* temp_abs_bool+tlrc.*

		done # \\ for CRITERIA

	done # \\ for DATASET

done # \\ for SUB_DIR
