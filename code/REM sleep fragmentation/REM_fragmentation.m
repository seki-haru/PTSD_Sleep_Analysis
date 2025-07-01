function RF = REM_fragmentation(data)
% Purpose: Calculate REM sleep fragmentation index
% REM sleep fragmentation: frequency of transition from REM to Wake during REM sleep
% data: sleep stage data starting and ending with sleep stage
% RF: average REM fragmentation index of each subject

% Initiate an empty array to store average REM fragmentation index of each subject
RF = [];

% Loop through each subject data
for i = 1:size(data,1)
     M = data{i,1};% Extract one subject data
     % Initiate an empty array to store REM sleep fragmentation index for each subject
     rf = [];

     % Loop through each night data
     for k = 1:size(M,2)
         N = M(:,k);% Extract one night data
         N(isnan(N)) = [];

         REM = sum(N == 4)*0.5;% Get total REM sleep time
         REM = REM/60; % Convert min to hour
         if REM == 0
             rf{k,1} = NaN;
         else
             r = count_occurrence_rf(N);% Count of REM interruption by Wake
             rf{k,1} = r/REM;% Calculate frequency
         end
     end
     RF{i,1} = mean(cell2mat(rf),1,'omitmissing');
end




function r = count_occurrence_rf(N)

prestage = NaN; % sleep stage of the previous epoch
r = 0; % to-Wake transition

% Count transition from REM to Wake
for i = 1:size(N,1)
    stage = N(i,1);
    if stage == 0
        if prestage == 4
            r = r+1; 
        end
    end              
    prestage = stage;
end