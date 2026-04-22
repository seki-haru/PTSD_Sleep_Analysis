function [out,TFR]=remove_first_0(data)
% Purpose: Exclude latency of the target stage
% data: 0/1 sleep stage data
% out: sleep stage data without latency
% TFR: average latency of each subject

% Loop through each subject data
for k = 1:size(data,1)

    M = data{k}; % Extract one subject data
    M(:,sum(M>0)==0) = []; % Discard subject data without chosen stage

    % Initiate an empty array to store sleep stage data without the latency
    m = [];
    % Initiate an empty array to store latency
    tfr = [];

    % Loop through each night data
    for i = 1:size(M,2)

        temp = M(:,i);%Extract one night data
        temp(isnan(temp)) = [];

        [s,ix] = get_segment(temp); % Segment the binary (0/1) data into episodes based on consecutive values
        % s: data segments of 0/1 episodes, ix: sleep stage for each episode (0 or 1)

        % Calculate latency
        if ix(1) == 0 % If the first episode is other stages
            tfr(i) = numel(s{1}); % Store the first episode duration as latency
        else
            tfr(i) = 0;% If not, latency == 0
        end

        % Discard data until the first episode
        if ix(1) == 0
            s(1) = [];
        end
        
        % Combine data segments and each night data again
        if size(s,2)>0
            m=catpad(2,m,segment2vector(s)');
        end
    end

    out{k,1} = m;
    TFR(k,1) = mean(tfr)/2;% Convert average latency to min 

end

% If there are subjects without any night data, delete their whole data.
rowsToDelete = find(cellfun(@isempty, out));
out(rowsToDelete,:)=[];
TFR(rowsToDelete,:)=[];

end