**Overview**

This repository contains MATLAB scripts for analyzing sleep structure based on 30-second epoch sleep stage data. The analyses are categorized into the following five modules and involve comparisons between healthy controls and people with PTSD.

1. Sleep regularity: the consistency of sleep-wake states at the same time across nights
2. Comparison of each sleep stage: episode latency, number, average duration, and NREM/REM sleep fragmentation (the frequency of transitions from NREM/REM to Wake)
3. Sleep stage probability: time-course probabilities of each sleep stage
4. Rhythmicity: Lomb-Scargle Periodogram to rhythmic occurrence of each sleep stage and episode interval variability

**Data description**

The ‘data’ directory contains two top-level folders; ‘Healthy’ and ‘PTSD’.

- Each of these folders includes subfolders for each participant, and each participant folder have individual files representing nightly sleep staging data.
- Sleep staging data are scored in 30-second epochs following AASM criteria.
- **The participant IDs and recording IDs used in this dataset were independently assigned by S’UIMIN Inc. and cannot be used to identify individuals.**

In addition, the directory also contains a file, ‘PDS-IV’, which includes the PDS-IV scores for each PTSD patient. 

**Environment**

MATLAB R2024a or later

**How to Run**

Each analysis folder is located under ‘Code’ and includes a ‘Main’ script that performs the analysis and generates the figure described in the paper.

1. Clone or download this repository
2. Open MATLAB and add the folder corresponding to the target analysis category to the MATLAB path.
3. Change the working directory to ‘data’.
4. Open and run the ‘Main’ script

**Figures/Tables generated**

1. Sleep regularity: Figure 2
2. Comparison of each sleep stage: Figure 3-4, S1
3. Sleep stage probability: Figure 5, S2
4. Rhythmicity: Figure 6, S3-7; Table 2, S1-2
