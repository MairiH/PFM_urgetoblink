#! /bin/bash

for SBJ in Sub01 Sub03 Sub04 Sub05 Sub06 Sub07 Sub09 Sub10 Sub11 Sub12 Sub13 Sub14 Sub15 Sub16 Sub17 Sub18 Sub19 Sub20 Sub21 Sub22; do
       for run in run01; do
              cwd=/mnt/h/Experiments/Experiment2-Blink_Tic/SPFM/feat_preproc/${SBJ}_${run}_echo01.feat/reg
              cd "${cwd}"
              fslmaths highres -bin highres_mask
              3dSeg -anat highres.nii.gz -mask highres_mask.nii.gz

              sdir=/mnt/h/Experiments/Experiment2-Blink_Tic/SPFM/feat_preproc/${SBJ}_${run}_echo01.feat/reg/Segsy
              cd "$sdir"
              3dAFNItoNIFTI Classes+orig.BRIK.gz
	done
done
