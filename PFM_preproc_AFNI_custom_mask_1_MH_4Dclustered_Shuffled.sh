#! /bin/bash

# Created/Written by Cesar Caballero Gaudes @ BCBL.
# Amended and adapted by Hilmar P Sigurdsson - email: hpsig86@gmail.com
# @ Nottingham 2018

# Path to data /Volumes/SILVER/Studies_ongoing/BFinND/TS030_09082018_BFinND/fMRI/Run01/Run01.feat
# Name of file: filtered_func_data.nii.gz
# Create percent signal change data with AFNI command 3dcalc: 
# 3dcalc -a filtered_func_data.nii.gz -b mean_func_nii.gz -expr '(a-b)/b' -prefix pc_filtered_func_data.nii.gz

if [ "$1" == "-h" ]; then
  echo "Usage: `basename $0` 
  [Insert cleaver description here]"
  exit 0
fi

# Then run 3dPFM command: 3dPFM -input pc_filtered_func_data.nii.gz -algorithm lasso -criteria bic -hrf SPMG1 -mask mask.nii.gz -maxiterfactor 0.4 -outZAll lasso_BIC_SPMG1 -jobs 4
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

	# ---- CREATE MASK IN NATIVE SPACE ---- 
		# # \\ Using FSL's FLIRT function
	# flirt -in ${MYMASK} -applyxfm -init reg/standard2example_func.mat -out ROI_in_Native -paddingsize 0.0 -ref mean_func.nii.gz 
		# # \\ Threshold and binarise
	# fslmaths ROI_in_Native.nii.gz -thr 0.35 -bin ${NATIVEMASK}

	# # ---- COMPUTE PERCENT SIGNAL CHANGE IMAGE -----
		# # \\ Assuming that filtered_func_data has non-zero mean, expr is (a-b)/b
		# # \\ If filtered_func_data has already zero_mean, expr is a/b, where b is the mean of the filtered_func_data before removing the mean (or detrending)
	# 3dcalc -a filtered_func_data.nii.gz -b mean_func.nii.gz -expr '(a-b)/b' -prefix pc_filtered_func_data.nii.gz -overwrite
	# echo "_____ Done computing percent signal change image = pc_filt_func_data _____"

		# # \\ Create surrogate dataset
	# 3dFFTshuffle -input pc_filtered_func_data.nii.gz -mask mask.nii.gz -prefix shuff -jobs 4
	# echo "Done computing surrogate dataset from pc_filt_func_data"

	for DATASET in ${SBJID%%_*}_${SBJID##*_}_BIC_SPMG1_EqualShuffle.DR2_4D_clust.nii.gz #pc_filtered_func_data.nii.gz shuff_pc_filtered_func_data.nii.gz
	do
		for CRITERIA in bic #aic
		do

			# PFX="lasso_${CRITERIA}_SPMG1"
			# echo -e "\033[1m____ This is the PFX = ${PFX} ____\033[0m"

			# echo -e "\033[1mComputing 3dPFM in ${DATASET} with ${CRITERIA} criteria\033[0m"
			# 3dPFM -input ${DATASET} -algorithm lasso -criteria ${CRITERIA} -hrf SPMG1 -mask mask.nii.gz -maxiterfactor 0.4 -outZAll ${PFX} -jobs 4
			# echo -e "\033[1m____ Done computing PFM for subj: ${sub_dir} and RUN${run} and DATASET ${DATASET}. Moving on to thresholding. ____\033[0m"

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
  					# 3dmerge -dxyz=1 -1clust 1 ${CLUSTERSIZE} -doall -prefix THC_beta_${DATASET} THAmp_beta_${DATASET} -overwrite
					
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
  				# # \\ Whole brain mask
  			# 3dmaskave -quiet -mask mask.nii.gz -sum temp_pos+tlrc. > ATSsum_pos.${ATS_DATASET:0:46}_4D_clust.1D
  			# 3dmaskave -quiet -mask mask.nii.gz -sum temp_pos_bool+tlrc. > ATSnum_pos.${ATS_DATASET:0:46}_4D_clust.1D
  			# #rm temp_pos+tlrc.* temp_pos_bool+tlrc.*
				# \\ ROI mask (insula + mid cingulate)
			3dmaskave -quiet -mask ${MYMASK} -sum temp_pos+tlrc. > ATSsum_pos.${ATS_DATASET:0:56}_${ROIMASK}.1D
			3dmaskave -quiet -mask ${MYMASK} -sum temp_pos_bool+tlrc. > ATSnum_pos.${ATS_DATASET:0:56}_${ROIMASK}.1D
  			rm temp_pos+tlrc.* temp_pos_bool+tlrc.*

  			# ---- NEGATIVE BETAS FOR DATASET
			echo -e "\033[1mComputing Activation Time Series NEGATIVE for ${DATASET}\033[0m"
  			3dcalc -a ${ATS_DATASET} -expr 'posval(-1*a)' -prefix temp_neg -overwrite
  			3dcalc -a ${ATS_DATASET} -expr 'ispositive(-1*a)' -prefix temp_neg_bool -overwrite
  				# # \\ Whole brain mask
  			# 3dmaskave -quiet -mask mask.nii.gz -sum temp_neg+tlrc. > ATSsum_neg.${ATS_DATASET:0:46}_4D_clust.1D
  			# 3dmaskave -quiet -mask mask.nii.gz -sum temp_neg_bool+tlrc. > ATSnum_neg.${ATS_DATASET:0:46}_4D_clust.1D
  			# #rm temp_neg+tlrc.* temp_neg_bool+tlrc.*
  				# \\ ROI MASK (insula + mid cingulate)
			3dmaskave -quiet -mask ${MYMASK} -sum temp_neg+tlrc. > ATSsum_neg.${ATS_DATASET:0:56}_${ROIMASK}.1D
			3dmaskave -quiet -mask ${MYMASK} -sum temp_neg_bool+tlrc. > ATSnum_neg.${ATS_DATASET:0:56}_${ROIMASK}.1D
  			rm temp_neg+tlrc.* temp_neg_bool+tlrc.*
  			
  			# ---- ABSOLUTE BETAS FOR DATASET
			echo -e "\033[1mComputing Activation Time Series ABSOLUTE for ${DATASET}\033[0m"
  			3dcalc -a ${ATS_DATASET} -expr 'abs(a)' -prefix temp_abs -overwrite
  			3dcalc -a ${ATS_DATASET} -expr 'bool(abs(a))' -prefix temp_abs_bool -overwrite
  				# # \\ Whole brain mask
  			# 3dmaskave -quiet -mask mask.nii.gz -sum temp_abs+tlrc. > ATSsum_abs.${ATS_DATASET:0:44}_4D_clust.1D
  			# 3dmaskave -quiet -mask mask.nii.gz -sum temp_abs_bool+tlrc. > ATSnum_abs.${ATS_DATASET:0:44}_4D_clust.1D
			# #rm temp_abs+tlrc.* temp_abs_bool+tlrc.*
				# \\ ROI MASK (insula + mid cingulate)
			3dmaskave -quiet -mask ${MYMASK} -sum temp_abs+tlrc. > ATSsum_abs.${ATS_DATASET:0:56}_${ROIMASK}.1D
			3dmaskave -quiet -mask ${MYMASK} -sum temp_abs_bool+tlrc. > ATSnum_abs.${ATS_DATASET:0:56}_${ROIMASK}.1D
  			rm temp_abs+tlrc.* temp_abs_bool+tlrc.*

		done # \\ for CRITERIA

	done # \\ for DATASET

done # \\ for SUB_DIR
