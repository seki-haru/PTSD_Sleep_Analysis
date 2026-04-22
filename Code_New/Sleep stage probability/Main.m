clear all
% Run on the folder storing sleep stage files
folderName = 'Healthy';
[T,N]=load_patient_data_raw_withName(folderName);% Load all subjects data. 'Healthy' or 'PTSD'
% T: sleep stage data by numeric values
% one subject data in each cell
% one cell data > row: bin(30s), column: each night
% 0==Wake, 1==N1, 2==N2, 3==N3, 4==R, 5==NotScored
% N: subject IDs (column1) and their recording IDs (column2)

latencyExclusion = 1; % 1==Start from sleep onset, 0==Start from record onset
if latencyExclusion == 1
    T = exclude_SL(T);% Exclude sleep latency
    % output: sleep stage data starting with sleep stage
end

% Initiate an empty array to store sleep stage data of all subjects
all_stage = [];
for a=1:size(T,1) 
    all_stage = catpad(1,all_stage,T{a,1}');
end

% Initiate an empty array to store number of occurrences of each sleep stage at each epoch
percentage = [];
for e=1:size(all_stage,2)
    percentage{1,e}=sum(all_stage(:,e)==0)+sum(isnan(all_stage(:,e))); % Wake: WASO + WAFA
    percentage{2,e}=sum(all_stage(:,e)==4); % REM
    percentage{3,e}=sum(all_stage(:,e)==1); % N1
    percentage{4,e}=sum(all_stage(:,e)==2); % N2
    percentage{5,e}=sum(all_stage(:,e)==3); % N3
    percentage{6,e}=sum(cell2mat(percentage(1:5,e))); % total number
end

% Calculate probability for each sleep stage
percentage = cell2mat(percentage)';
percentages = percentage(:, 1:5) ./ percentage(:, 6);

% Make a figure of sleep stage probability
figure; hold on;
x = (1:size(percentages,1)) - 1;
stucked_figure = area(x, percentages(:,1:5));


% Color setting for each sleep stage
stucked_figure(1).FaceColor = [0 0 0];
stucked_figure(2).FaceColor = [1 0 0];
stucked_figure(3).FaceColor = [0.92 0.95 1];
stucked_figure(4).FaceColor = [0.73 0.81 1];
stucked_figure(5).FaceColor = [0.13 0.31 0.73];

set(stucked_figure, 'EdgeColor', 'none');
ax = gca;

% x tick setting
xlim([0, size(percentages,1)]);
xticks(0:200:1400);
xticklabels({'0', '100', '200', '300', '400', '500', '600', '700'});
ax.XAxis.FontSize = 18;
if latencyExclusion == 1
    xlabel('Time from sleep onset [m]', 'FontSize', 25);
else
    xlabel('Time from start of recording [m]', 'FontSize', 25);
end

% y tick setting
ylim([0, 1]);
yticks(0:0.1:1);
ax.YAxis.TickDirection = 'out'; 
ax.YAxis.TickLength = [0.02 0.01];
ax.YAxis.LineWidth = 1.5;
ax.YTickLabel = [];
ylabel('Probability','FontSize', 25);

% Title
title(folderName,'FontSize',25);

% Legend
leg = legend({'Wake','REM','N1','N2', 'N3'}, 'Location', 'northeastoutside','FontSize',18);
leg.Position = [0.9, 0.8, 0.1, 0.1];
