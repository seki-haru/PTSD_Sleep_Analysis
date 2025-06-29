clear all

% Run on the folder storing sleep stage files
[T,N]=load_patient_data_raw_withName('Healthy'); % Load all subjects sleep data. 'Healthy' or 'PTSD'
% T: sleep stage data by numeric values
% one subject data in each cell
% one cell data > row: bin(30s), column: each night
% 0==Wake, 1==N1, 2==N2, 3==N3, 4==R, 5==NotScored
% N: subject IDs (column1) and their recording IDs (column2)
T_SL = exclude_SL(T); % Exclude sleep latency
% T_SL: sleep stage data starting with sleep stages


data = stage_replace(T_SL, 4);% Separate the target sleep stage from others
% data: 0/1 sleep stage data (1==chosen stage 0==other stages)
[observed_mean,M] = get_average_data(data); % Get the average probability across all subjects
% observed_mean: the average probability across all subjects
% M: accumulated average probability of each subject
% row(M): each subject, column: bin(30s)
figure; plot(observed_mean); % Plot observed_mean (X axis: bin number, Y axis: probability)

%% Align the start of each night's data to the onset of the first episode 

[data,TFR] = remove_first_0(data);% Exclude latency of the target stage
% data: sleep stage data without latency
% TFR: average latency of each subject

% Perform F test to check the variability of latency
% Calculate the 95% confidence interval for the SD of latency (Bias-corrected and acelerate bootstrap)
ci = bootci(1000,@(x) std(x),TFR); 
[std(TFR),flip(ci')] % Print observed SD, upper ci, and lower ci.

[observed_mean,M] = get_average_data(data); % Get the average probability of each subject and across all subjects again
figure; imagesc(M); % Plot M (X axis:bin number, Y axis:subject number)
figure; plot(observed_mean); % Plot observed_mean (X axis: bin number, Y axis: probability)



[xCov,X] = get_xCov_patient(M); % Get the autocorrelation of average probability of each subject 
% out: accumulated the autocorrelation of average probability of each subject
% X: accumulated shifted bin numbers of each subject
% row: subject number, column: bin (30s)
x = 0:(size(xCov,2)-1);
figure; plot(x,mean(xCov,'omitmissing'),"-r","LineWidth",2) % Plot mean xCov (X axis: bin number, Y axis: autocorrelation)

%% If there is any inadequate data, choose a option to delete it.

% Delete subjects with too short data after the first episode (REM, N2)
data_duration = get_data_duration(M); % Get bin number of average data after the first episode of each subject
criteria_bin = 366; % Set the minimum bin number (the second peak of autocorrelation figure in Healthy group: REM 366, N2 407)
data = exclude_short_data(data,criteria_bin);
% data: sleep stage data without shorter data than the criteria

% Delete subjects with few episodes (N3)
E = get_episode_info(data); % Get average episode number and duration of each subject
EN = cell2mat(table2array(E(:,2))); % Extract average episode number of each subject
Q1 = prctile(EN, 25); % Q1 of PTSD group
criteria_episode = 4.4; % Set the minimum episode number
data = exclude_few_episode_data(data,EN,criteria_episode);
% data: sleep stage data without data with fewer episodes than the criteria

%% Confirm that there is not inadequate data 

[observed_mean,M] = get_average_data(data); % Get the average probability of each subject and across all subjects again
figure; imagesc(M); % Plot M (X axis:bin number, Y axis:subject number)
figure; plot(observed_mean); % Plot observed_mean (X axis: bin number, Y axis: probability)
[xCov,X] = get_xCov_patient(M); % Get the autocorrelation of average probability of each subject again
x = 0:(size(xCov,2)-1); 
figure; plot(x,mean(xCov,'omitmissing'),"-r","LineWidth",2) % Plot mean xCov (X axis: bin number, Y axis: autocorrelation)

%% This block will calculate the autocorrelation and average probability in shuffle data (random chance)

% Initiate an empty array to store the probability and autocorrelation of shuffuled data
sSample = []; % probability
r_xc = []; % autocorrelation

% Initiate an empty cell array to store the autocorrelation of average probability of each subject shuffled data
individualA = cell(size(data));


% Shuffle 1000 times
for s=1:1000

    shuffle_sample = data_shuffle(data); % Shuffle episode(1) & interval(0) within each night
    % shuffle_sample: shuffled episode(1) & interval(0) starting with the target stage (1)

    [temp,tempM] = get_average_data(shuffle_sample); % Get the probability of each subject and across all subjects (shuffled)
    [temp_xCov,~] = get_xCov_patient(tempM); % Get the autocorrelation of average probability of each subject (shuffled)

    % Sort and save the autocorrelation for each subject
    for k = 1:size(temp_xCov,1)
        t = temp_xCov(k,:);
        t(isnan(t)) = [];
        individualA{k,s} = t;
        % one subject data in each row
        % an autocorrelation from a single shuffling in each cell
        % one cell data > column: bin (30s)
    end

    r_xc = catpad(1,r_xc,mean(temp_xCov,'omitmissing')); % Store the average autocorrelation across all subjects (shuffled)
    sSample = catpad(1,sSample,temp); % Store the average probability across all subjects (shuffled)
    % column: bin (30s)
end

% Initiate an empty array to store accumulated average autocorrelation of each subject shuffled data
Shuffle_xCov = [];
% Loop through each subject data
for i = 1:size(individualA,1)
    all_A = individualA(i,:); % Extract the autocorrelations of each subject shuffled data
    all_A = segment2vector(all_A);
    average_A = (mean(all_A,2))'; % average of 1000 autocorrelations
    Shuffle_xCov = catpad(1,Shuffle_xCov,average_A);
    % row: each subject, column: bin(30s)
end


%% Plot observed average probability vs randomly shuffled probability

err_low = prctile(sSample,2.5,1);% Get upper limit of the probability in shuffled data
err_up = prctile(sSample,97.5,1);% Get lower limit of the probability in shuffled data

x = (0:0.5:numel(observed_mean)/2-0.5); % X axis:minutes
figure; plot(x,observed_mean,"-r","LineWidth",2)% Plot the probability of observed data
hold on;
plot(x,mean(sSample),"-k","LineWidth",2)% Add the average probability and its 95% confidence interval of shuffled data
plot(x,err_up,"-k")
plot(x,err_low,"-k")

P = [x',mean(sSample)',err_up',err_low',observed_mean'];  % Plot this in graphpad



%% Plot observed autocorrelation vs randomly shuffled autocorrelation

err_low = prctile(r_xc,2.5,1);% Get upper limit of the autocorrelation in shuffled data
err_up = prctile(r_xc,97.5,1);% Get lower limit of the autocorrelation in shuffled data


x = (0:(size(xCov,2)-1))/2; % X axis:minutes
figure; plot(x,mean(xCov,'omitmissing'),"-r","LineWidth",2)% Plot the autocorrelation of observed data
hold on;
plot(x,mean(r_xc),"-k","LineWidth",2)% Add the average autocorrelation and its 95% confidence interval of shuffled data
plot(x,err_up,"-k")
plot(x,err_low,"-k")

A = [x',mean(r_xc,'omitmissing')',err_up',err_low',mean(xCov,'omitmissing')']; % Plot this in graphpad

%% Calculate autocorrelation for each subject

Th = define_analysis_window(data); % Define analysis window for the rhythmicity 
% Th: the time point at which ≥50% of each subject’s recordings remained
% row: each subject

% Initiate an empty array to store the deviation from the shuffled data, measured as RMSE
RMSE = [];
% Loop through each subject data
for i = 1:size(xCov,1)
    match = [xCov(i,:); Shuffle_xCov(i,:)];
    distance = match(1,:)-match(2,:); % Calculate the distance between the observed data and the shuffled data every epoch
    w = Th(i,1); % Find the final epoch of analysis window

    % Calculate RMSE within the analysis window
    squared_distance = distance(1,1:w).^2;
    RMSE(i,1) = sqrt(mean(squared_distance));
    % row: each subject
end

%% Calculate SD of interval durations for each night

interval = get_interval_duration(data);% Calculate interval durations across all nights
% Perform fitting the interval (Healthy) by a two-Gaussian model on lgor pro
% -> the optimal separation point between the two peaks was approximately 17.1 minutes

criteria_interval = 17.1;
SD = get_interval_SD(data, criteria_interval);% Calculate the SD of interval durations (> criteria) in each night
% row: each night