function interval = get_interval_duration(data)
% Purpose: Calculate interval durations across all nights
% data: sleep stage data without shorter data than the criteria
% interval: interval durations across all nights

% Initiate an empty array to store interval durations across all nights
interval = [];

% Loop through each subject data
for k=1:size(data,1)
    M=data{k}; % Extract one subject data

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

        interval  = [interval; DIX(2,:)']; % Store all interval durations
    end
end

