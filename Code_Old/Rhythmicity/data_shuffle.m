function shuffled_data  = data_shuffle(data)
% Purpose: Shuffle episode(1) & interval(0) within one night
% data: sleep stage data starting with the target stage
% shuffled_data: shuffled episode(1) & interval(0) starting with the target stage (1)

% Initialize a cell array to store shuffled data
shuffled_data = cell(size(data));

% Loop through each subject data
for k = 1:numel(data)
    temp = data{k}; % Extract one subject data

    % Loop through each night data
    for i = 1:size(temp,2)
        x = temp(:,i); % Extract one night data
        ix = isnan(x);
        x(ix) = [];

        [s,six] = get_segment(x); % Segment binary (0/1) data into episodes based on consecutive values
        % s: data segmented into 0/1 episodes, six: sleep stage for each episode (0 or 1)

        % Shuffle the order of 0/1 episodes
        r = randperm(numel(six));
        s = s(r);
        six = six(r);

        if six(1)==0 % Force the sequence to start with 1
            fz=find(six==1,1); % Find the first 1
            s=[s(fz:end),s(1:fz-1)];% Add data before the first 1 to the last 
        end

        
        temp(~ix,i) = segment2vector(s); % Combine segmented data again
    end
    
    shuffled_data{k,1}=temp;
end
