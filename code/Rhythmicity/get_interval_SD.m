function SD = get_interval_SD(data, criteria)
% Purpose: Calculate the SD of interval durations (> criteria) in each night
% data: sleep stage data without shorter data than the criteria
% criteria: the shortest interval duration [m]
% SD: the SD of interval durations in each night

% Initiate an empty array to store the SD of interval durations in each night
SD = [];

% Loop through each subject data
for k = 1:size(data,1)
    M = data{k}; % Extract one subject data

    % Loop through each night data
    for i =1:size(M,2)
        temp=M(:,i); % Extract one night data
        temp(isnan(temp))=[];

        [s,ix] = get_segment(temp); % Segment the binary (0/1) data into episodes based on consecutive values
        % s: data segments of 0/1 episodes, ix: sleep stage for each episode (0 or 1)
        d = cellfun(@(x) size(x,1)*0.5,s); % Convert segments duration from seconds to minutes
        DIX=[ix;d];

        % Exclude data after the last episode of the target stage
        if DIX(1, end) == 0
            DIX(:, end) = [];
        end
        DIX(:,DIX(1,:)==1)=[]; % Exclude episodes and left their intervals

        DIX(:,DIX(2,:)<=criteria)=[]; % Exclude episode intervals shorter than the criteria

        % Calculate the SD of intervals
        if size(DIX,2) >= 2
            SD(end+1,1) = std(DIX(2,:));
        end
    end
end
