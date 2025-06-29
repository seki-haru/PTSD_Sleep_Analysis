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