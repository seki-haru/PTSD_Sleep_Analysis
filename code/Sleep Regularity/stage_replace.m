function out = stage_replace(T,s)
% Purpose: Separate the target sleep stage from others
% T: sleep stage data, s: the target sleep stage
% out: 0/1 sleep stage data (1==chosen stage 0==other stages)

% Loop through each subject data
for k = 1:size(T,1)

    data = T{k};% Extract one subject data

    % Loop through each night data
    for i = 1:size(data,2)

        temp = data(:,i);% Extract one night data

        for n = 1:length(temp)
            if temp(n,1) == s
                temp(n,1) = 1; % Convert the chosen stage to 1
            else
                if ~isnan(temp(n,1))
                    temp(n,1) = 0;% Convert other stages to 0
                end
            end
        end

        data(:,i) = temp;

    end

    out{k,1} = data;

end



