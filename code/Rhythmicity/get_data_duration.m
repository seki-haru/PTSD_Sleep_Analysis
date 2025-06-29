function duration = get_data_duration(M)
% Purpose: Get bin number of average data after the first episode of each subject
% M: accumulated average probability after the first episode of each subject
% duration: bin number of average data after the first episode of each subject

% Initiate an empty array to store bin number of average data after the first episode of each subject
duration = [];

% Loop through each subject data
for k = 1:size(M,1)
    temp = M(k,:);% Extract average data after the first episode of one subject
    temp(isnan(temp)) = [];
    duration(k,1) = length(temp);% Get bin number of the data
end

figure;plot(ones(size(duration)), duration, 'r.', 'MarkerSize', 10); % Plot data durations

