function data = exclude_short_data(data,criteria)
% Purpose: Delete subject with too short data after the first episode
% criteria: the minimum bin number
% data: sleep stage data without latency -> + without shorter data than the criteria

rowsToDelete = find(cellfun(@(x) length(x)< criteria, data));% Find shorter data than the criteria
data(rowsToDelete,:) = [];% Exclude whole data of the applicable patient

