function Th = define_analysis_window(data)
% Purpose: Define analysis window for the rhythmicity
% data: sleep stage data starting with the target stage
% Th: the time point at which ≥50% of each subject’s recordings remained

% Initiate an empty array to store the time point 
% at which ≥50% of each subject’s recordings remained
Th = [];

% Loop through each subject data
for k = 1:size(data,1)
    D = data{k,1}; % Extrach one subject data

    threshold = size(D,2)/2; % 50% number of each subject’s recordings
    valid_counts = sum(~isnan(D),2); % the number of remained recordings

    Th(k,1) = find(valid_counts >= threshold,1,'last'); % find the last time point at which ≥50% of each subject’s recordings remained

end
end
