clear all

% Run on the folder storing sleep stage files
[T,N]=load_patient_data_raw_withName('PTSD'); % Load all subjects sleep data. 'Healthy' or 'PTSD'
% T: sleep stage data by numeric values
% one subject data in each cell
% one cell data > row: bin(30s), column: each night
% 0==Wake, 1==N1, 2==N2, 3==N3, 4==R, 5==NotScored
% N: subject IDs (column1) and their recording IDs (column2)
T_Wake = exclude_Wake(T);% Exclude sleep latency and wake time after final awaking
% T_Wake: sleep stage data starting and ending with sleep stage


data = stage_replace(T_Wake, 0);% Separate the target sleep stage from others
% data: 0/1 sleep stage data (1==chosen stage 0==other stages)
[data,TFR] = remove_first_0(data);% Exclude latency of the target stage
% data: sleep stage data without latency
% TFR: average latency of each subject

% Get average episode number and duration of each subject
E = get_episode_info(data);
% one subject data in each row