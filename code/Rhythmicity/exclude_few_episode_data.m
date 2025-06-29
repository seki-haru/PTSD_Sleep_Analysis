function data = exclude_few_episode_data(data,EN,criteria_episode)
% Purpose: Delete subject with few episodes not to underestimate the rhythmicity
% EN: average episode number of each subject
% criteria_episode: the minimum episode number
% data: sleep stage data without latency -> + without data with fewer episodes than the criteria

rowsToDelete = find(EN < criteria_episode); % Find data with fewer episodes than the criteria
data(rowsToDelete,:) = []; % Exclude whole data of the applicable patient
