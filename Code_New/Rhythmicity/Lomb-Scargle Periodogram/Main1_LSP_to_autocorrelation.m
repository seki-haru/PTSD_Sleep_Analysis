% Run on the folder storing sleep stage files

clear all
% Load all participants sleep data
[T,N]=load_patient_data_raw_withName('Healthy'); % 'Healthy' or 'PTSD'
% T: sleep stage data by numeric values
% one participant data in each cell> row: bin(30s), column: each night
% N: subject IDs (column1) and their recording IDs (column2)

% Exclude sleep latency
T_SL = exclude_SL(T);
% T_SL: sleep stage data starting with sleep stages

% Separate the target sleep stage from others
data = stage_replace(T_SL, 4); % 0==Wake, 1==N1, 2==N2, 3==N3, 4==REM, 5==NotScore
% data: 0/1 sleep stage data (1==chosen stage 0==other stages)

% Get the average probability across all participants
[observed_mean,~] = get_average_data(data); 

figure; plot(observed_mean);
xt = xticks;
xticklabels((xt-1) / 2);
xlabel('Time from sleep onset [m]');
ylabel('Probability');


%% Align the start of each night's data to the onset of the first episode 

% Exclude latency of the target stage
[data,TFR] = remove_first_0(data);
% data: sleep stage data without latency
% TFR: average latency of each subject

% Calculate the 95% confidence interval for the SD of latency (Bias-corrected and acelerate bootstrap)
ci = bootci(1000,@(x) std(x),TFR); 
[std(TFR),flip(ci')] % Print observed SD, upper ci, and lower ci.

% Get average probability of each participant and across all participants
[observed_mean,M] = get_average_data(data); 

figure; imagesc((1:size(M,2)) - 0.5, 1:size(M,1), M); colorbar;
xt = xticks;
xticklabels(xt / 2);
xlabel('Time from onset of the first episode [m]');
ylabel('Participant ID');

x = 0:(size(observed_mean,2)-1);
figure; plot(x,observed_mean);
xt = xticks;
xticklabels(xt / 2);
xlabel('Time from onset of the first episode [m]');
ylabel('Probability');
title('Group-averaged probability');

% Get autocorrelation function of average probability of each participant
[xCov,X] = get_xCov_patient(M);

x = 0:(size(xCov,2)-1);
figure; plot(x,mean(xCov,'omitmissing')) % averge autocorrelation function across all participants
xt = xticks;
xticklabels(xt / 2);
xlabel('Time lag [m]');
ylabel('Autocorrelation function');
title('Group-averaged autocorrelation function');


%% Lomb–Scargle periodograms
epoch_minutes=0.5;
periods = (200:-1:1)'; % the candidate periods (minutes)
fgrid   = 1./periods;  % corresponding frequencies
Fs = 1 / epoch_minutes; % sampling frequency
% Perform LSP to average autocorrelation
[metric_matrix, ~] = plomb(mean(xCov,'omitmissing'), Fs, fgrid, 'normalized');

figure;
plot(periods, metric_matrix);
xlabel('Period [m]');
ylabel('Normalized PSD');
title('LSP of autocorrelation function');


function [out,meanPatient]=get_average_data(data)
% Get average probability of each participant and across all participants

meanPatient = [];

for i = 1:size(data,1)
    Patient = data{i, 1}';
    meanPatient = catpad(1,meanPatient,mean(Patient,1,'omitmissing')); % Calculate average probability of each participant
end

out = mean(meanPatient,1,'omitmissing'); % Calculate average probability across all participants
end

function [out,X]=get_xCov_patient(meanPatient)
% Get autocorrelation function of average probability of each participant

out = [];
X = []; % shifted bin numbers

for i = 1:size(meanPatient,1)
    t = meanPatient(i,:);
    t(isnan(t)) = [];

    % Calculate autocorrelation function of average probability of each participant
    [temp,x] = xcov(t,'coeff');

    % Delete negative values
    temp(x<0) = [];
    x(x<0) = [];

    % Accumulate autocorrelation functions across all participants
    out = catpad(1,out,temp);
    X = catpad(1,X,x);
end
end