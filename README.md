# PTSD_Sleep_Analysis
Overview
This repository contains MATLAB scripts for analyzing sleep structure based on 30-second epoch sleep stage data. The analyses are categorized into the following five modules and involve comparisons between healthy controls and people with PTSD.

1.	Sleep regularity: the consistency of sleep-wake states at the same time across nights
2.	Episode Information: episode latency, number, average duration of each sleep stage
3.	REM sleep fragmentation: the frequency of transitions from REM to Wake
4.	Sleep stage probability: Time-course probabilities of each sleep stage
5.	Rhythmicity: the rhythmicity of the probability peak of each sleep stage

Data description
The ‘data’ directory contains two top-level folders; ‘Healthy’ and ‘PTSD’.
- Healthy
- PTSD
Each of these folders includes subfolders for each participant, and within each participant folder are individual files representing nightly sleep staging data.
- Sleep staging data are scored in 30-second epochs following AASM criteria.
- Each file corresponds to one night of recording
**The participant IDs used in this dataset were independently assigned by S’UIMIN Inc. and cannot be used to identify individuals.**

Environment
MATLAB R2024a or later

How to Run
Each analysis folder is located under ‘Code’ and includes a ‘Main’ script that performs the analysis and generates the figure described in the paper.
1.	Clone or download this repository
2.	Open MATLAB and add the folder corresponding to the target analysis category　 to the MATLAB path.
3.	Change the working directory to ‘Data’.
4.	Open and run the ‘Main’ script

Figures generated
1.	Sleep regularity: Figure 2
2.	Episode Information: Figure 4b-d
3.	REM sleep fragmentation: Figure 4e
4.	Sleep stage probability: Figure 5, S2
5.	Rhythmicity: Figure 6,7, S3-5
