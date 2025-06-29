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