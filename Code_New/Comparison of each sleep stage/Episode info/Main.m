clear all

% Run on the folder storing sleep stage files
[T,N]=load_patient_data_raw_withName('Healthy'); % Load all subjects sleep data. 'Healthy' or 'PTSD'
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

function T_Wake = exclude_Wake(T)
% Purpose: Exclude sleep latency and wake time after final awaking
% T: sleep stage data
% T_Wake: sleep stage data starting and ending with sleep stage

% Loop through each subject data
for k = 1:size(T,1)

    M = T{k};% Extract one subject data
    % Initiate an empty array to store data without sleep latency
    m = [];

    % Loop through each night data
    for i = 1:size(M,2)
        temp = M(:,i);% Extract one night data
        temp(isnan(temp)) = [];

        % Find any sleep stage
        idx = find(temp ~= 0 & temp ~= 5);
        if ~isempty(idx)
            first_row = idx(1); % the first sleep stage
            last_row  = idx(end); % the last sleep stage

            % Extract data from the first to the last sleep stage
            temp = temp(first_row:last_row);
        end
      
        m = catpad(2,m,temp);
    end
    T_Wake{k,1} = m;
end
end

function E = get_episode_info(data)
% Purpose: Get average episode number and duration of each subject
% data: sleep stage data without latency
% E: average episode number and duration of each subject


% Loop through each subject data
for k = 1:size(data,1)
    M = data{k}; % Extract one subject data

    % Initiate an empty array to store average episode info of each subject
    Number = []; % episode number
    AveDuration = []; % average episode duration in one night

    % Loop through each night data
    for i =1:size(M,2)
        temp=M(:,i); % Extract one night data
        temp(isnan(temp))=[];

        [s,ix] = get_segment(temp); % Segment the binary (0/1) data into episodes based on consecutive values
        % s: data segments of 0/1 episodes, ix: sleep stage for each episode (0 or 1)
        d = cellfun(@(x) size(x,1)*0.5,s); % Convert segments duration from seconds to minutes
        DIX=[ix;d];

        DIX(:,DIX(1,:)==0)=[]; % Exclude episode intervals

        % Store the episode number and average episode duration in one night
        Number = [Number, size(DIX,2)];
        AveDuration = [AveDuration, mean(DIX(2,:))];    
    end

    E{k,1} = Number;
    E{k,2} = mean(Number);% mean episode number across nights
    E{k,3} = AveDuration;
    E{k,4} = mean(AveDuration);% mean episode duration across nights
end

E = array2table(E, 'VariableNames', {'Number', 'Mean Number', 'Duration', 'Mean Duration'});
end