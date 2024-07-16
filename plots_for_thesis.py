import os
from pdb import set_trace as bp

import matplotlib.pyplot as plt
from matplotlib.pyplot import scatter
import numpy as np
from matplotlib.lines import Line2D

colors = ["#e06666", "#189AD3"]

# Plotting font size to 22
plt.rcParams.update({"font.size": 22})

PRJDIR = "/mnt/d/Experiments/Experiment2-Blink_Tic/SPFM/02_Statistics"

# Plotting function
def plot_ats(
    time,
    urge,
    fd,
    blink,
    ats_neg_ins,
    ats_ins_shuffNEG_median,
    prefix,
    rss_pos,
    rss_neg
):
    #  Subplot of 5 rows and 1 column
    # fig, ax = plt.subplots(5, 1, figsize=(20, 30),gridspec_kw={'height_ratios': [1, 2, 2, 2, 2]})
    #  Subplot of 5 rows and 1 column
    fig, ax = plt.subplots(3, 1, figsize=(20, 30),gridspec_kw={'height_ratios': [1, 2, 2]})

    # Plot the FD time-series
    ax[0].plot(time, fd[15:217], color="#6aa84f", label="FD")
    ax[0].set_ylabel("FD")
    ax[0].set_xlabel("Time (s)")
    ax[0].set_xlim([0, 360])
    
    # Add custom legend for FD
    custom_lines = [Line2D([0], [0], color="#6aa84f", lw=2)]
    #ax[0].vlines(x=[60, 120, 180, 240, 300, 360], ymin=-2.5, ymax=3, color="black", ls='--', lw=4)
    ax[0].legend(custom_lines, ["FD"], loc="upper right")
    
    # Add title of FD time-series
    ax[0].set_title("Framewise Displacement")

    # Plot the urge time-series
    ax[1].plot(time, urge[15:217], color="magenta", label="Urge")
    ax[1].set_ylabel("Urge (z-score)")
    ax[1].set_xlabel("Time (s)")
    ax[1].set_xlim([0, 360])
    
    #  Plot the blink time-series with its own scale
    ax1a = ax[1].twinx()
    ax1a.plot(time, blink[15:217], color="#6aa84f", label="Blinks")
    ax1a.set_ylabel("Blinks")
    ax1a.set_xlim([0, 360])
    
    # Add legend
    custom_linesa = [
        Line2D([0], [0], color="magenta", lw=2),
        Line2D([0], [0], color="#6aa84f", lw=2),
    ]
    ax[1].legend(custom_linesa, ["Urge", "Blinks"], loc="upper right")
    
    # Add title of urge time-series
    
    ax[1].set_title("Urge and blink time-series")

    
    # Plot the negative ATS of insula above_threshold
    # Threshold value
    #threshold = ats_ins_shuffNEG_median

    #above_threshold = [x - threshold if x > threshold else 0 for x in ats_neg_ins]

    # Plot above_threshold data
    #ax[2].plot(time,above_threshold,color=colors[1], label="ATS neg. Insula")
    #ax[2].set_ylabel("Insula Voxels")
    #ax[2].set_xlabel("Time (s)")
    #ax[2].set_xlim([0, 360])

    # Add legend
    #custom_linesa = [
    #    Line2D([0], [0], color=colors[1], lw=2),
    #]
    #ax[2].legend(custom_linesa, ["Insula"], loc="upper right")
    
    # Add title of negative ATS of insula
    #ax[2].set_title("Positive BOLD ATS above threshold")

    # Plot the negative ATS of insula and threshold line
    ax[2].plot(time, ats_neg_ins, color=colors[1], label="ATS neg. Insula")
    ax[2].hlines(y=ats_ins_shuffNEG_median, xmin=0, xmax=432, color="navy", label="Null", lw=2)
    ax[2].set_ylabel("Insula Voxels")
    ax[2].set_xlabel("Time (s)")
    ax[2].set_xlim([0, 360])
    ax[2].vlines(ymin=-10,ymax=170, x=(26*1.8), color="black", label="Null", lw=1, linestyle='--')
    ax[2].vlines(ymin=-10,ymax=170, x=(36*1.8), color="black", label="Null", lw=1, linestyle='--')
    ax[2].vlines(ymin=-10,ymax=170, x=(37*1.8), color="black", label="Null", lw=1, linestyle='--')
    ax[2].vlines(ymin=-10,ymax=170, x=(38*1.8), color="black", label="Null", lw=1, linestyle='--')
    ax[2].vlines(ymin=-10,ymax=170, x=(70*1.8), color="black", label="Null", lw=1, linestyle='--')
    ax[2].vlines(ymin=-10,ymax=170, x=(86*1.8), color="black", label="Null", lw=1, linestyle='--')
    ax[2].vlines(ymin=-10,ymax=170, x=(98*1.8), color="black", label="Null", lw=1, linestyle='--')
    ax[2].vlines(ymin=-10,ymax=170, x=(123*1.8), color="black", label="Null", lw=1, linestyle='--')
    ax[2].vlines(ymin=-10,ymax=170, x=(124*1.8), color="black", label="Null", lw=1, linestyle='--')
    ax[2].vlines(ymin=-10,ymax=170, x=(172*1.8), color="black", label="Null", lw=1, linestyle='--')

    ax[2].set_ylim([-5, 170])

    # Add legend
    custom_linesa = [
        Line2D([0], [0], color=colors[1], lw=2),
        Line2D([0], [0], color="navy", lw=2),
        Line2D([0], [0], color="black", lw=1, linestyle='--')
    ]
    ax[2].legend(custom_linesa, ["Insula","Threshold","Selected peak"], loc="upper right")

    # Add title of negative ATS of insula
    ax[2].set_title("Positive BOLD ATS")

    # Plot the positive rss
    #ax[4].plot(time, rss_pos, color=colors[0], label="RSS pos.")
    #ax[4].set_xlabel("Time (s)")
    #ax[4].set_xlim([0, 360])

    # Add title of positive rss
    #ax[4].set_title("RSS for regions in the right insula")

    # Plot the negative rss with its own scale
    #ax[4].plot(time, -rss_neg, color="#6aa84f", label="RSS neg.")
    #ax[4].set_ylabel("RSS")


    fig.tight_layout(pad=1.0)

    # Save figure with subject names and runs
    plt.savefig(f"{prefix}_plots_for_thesis_new.png")


def _main():

    # TR and number of samples
    TR = 1.8
    n_samples = 202

    #  Generate time array
    time = np.arange(0, n_samples) * TR

    # Files in current directory
    files = os.listdir()

    #  ATS options
    ats_options = ["num", "sum"]

    #  Loop through ATS options
    for ats_option in ats_options:
        #  Get urge file name and read file
        urge_file = [f for f in files if f.endswith("urge_zscore_interp.txt")][0]
        urge = np.loadtxt(urge_file)

        #  Get fd file name and read file
        fd_file = [f for f in files if f.endswith("_FD.1D")][0]
        fd = np.loadtxt(fd_file)
        
        #  Get blink file name and read file
        blink_file = [f for f in files if f.endswith("_blink_interp.txt")][0]
        blink = np.loadtxt(blink_file)
        blink = np.round(blink)

        #  Get negative ATS of Insula file name and read file
        neg_ats_file_ins = [
            f for f in files if f.startswith(f"ATS{ats_option}_neg") and f.endswith("BIC_SPMG1.DR2_4D_clust_Ins.1D")
        ][0]
        ats_neg_ins = np.loadtxt(neg_ats_file_ins)

        #  Find "Sub" substring in abs_ats_file_ins
        sub = neg_ats_file_ins[neg_ats_file_ins.find("Sub") : neg_ats_file_ins.find("Sub") + 5]
        run = neg_ats_file_ins[neg_ats_file_ins.find("run") : neg_ats_file_ins.find("run") + 5]

        #  Generate prefix with subject name, run and ATS option
        prefix = f"{sub}_{run}_{ats_option}_4D_clust"
        
        # Data directory
        data_dir = os.path.join(PRJDIR, sub, run)
        
        #  Read ATS file
        ats_ins_shuffNEG_file = os.path.join(
            data_dir, f"ATS{ats_option}_neg.THC_beta_{sub}_{run}_BIC_SPMG1_EqualShuffle.DR2_4D_clust_Ins.1D"
        )
        ats_ins_shuffNEG = np.loadtxt(ats_ins_shuffNEG_file)
        
        # Find the median of the ats_ins_shuff data
        ats_ins_shuffNEG_median = np.median(ats_ins_shuffNEG)   

        # Get rss positives file name and read file
        rss_pos_file = [f for f in files if f.endswith("_rss_pos_thesis.1D")][0]
        rss_pos = np.loadtxt(rss_pos_file)

        # Get rss negatives file name and read file
        rss_neg_file = [f for f in files if f.endswith("_rss_neg_thesis.1D")][0]
        rss_neg = np.loadtxt(rss_neg_file)   

        #  Plot ATS
        plot_ats(
            time,
            urge,
            fd,
            blink,
            ats_neg_ins,
            ats_ins_shuffNEG_median,
            prefix,
            rss_pos,
            rss_neg
        )


if __name__ == "__main__":
    _main()
