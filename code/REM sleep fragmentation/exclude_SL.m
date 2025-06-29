function T_SL = exclude_SL(T)
% Purpose: Exclude sleep latency
% T: sleep stage data
% T_SL: sleep stage data starting with sleep stages

% Loop through each subject data
for k = 1:size(T,1)

    M = T{k};% Extract one subject data
    % Initiate an empty array to store the data without sleep latency
    m = [];

    % Loop through each night data
    for i = 1:size(M,2)
        temp = M(:,i);% Extract one night data
        temp(isnan(temp)) = [];
        
        % Count bins until any sleep stage
        L = 0; % bin number
        for n = 1:length(temp)
            if temp(n) == 0 || temp(n) == 5 % If the stage is Wake or NotScored
                L = n; % Update the bin number
            else
                break
            end
        end

        % Delete sleep latency
        if L~=0
            temp(1:L) = [];
        end
        
        m = catpad(2,m,temp);
    end

T_SL{k,1} = m;

end
