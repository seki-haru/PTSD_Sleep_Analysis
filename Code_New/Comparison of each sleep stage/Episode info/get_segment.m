function [segments,ix]=get_segment(v)
% Purpose: Segment binary (0/1) data into episodes based on consecutive values
% v: 0/1 sleep stage data for one night
% segments: data segments of 0/1 episodes
% ix: sleep stage for each episode (0 or 1)

% Initiate an empty cell array to store data segments of 0/1 episodes
segments = {};
% Initiate an empty array to store sleep stages for each episode (0 or 1)
ix = [];

% Initialize segment position and count
segment_start = 1; % epoch number of the beggining of the episode
k = 1; % episode number

for i = 2:length(v)
    if v(i) ~= v(i-1)
        % When a sleep stage change is detected, store the segment and sleep stage
        segments{end+1} = v(segment_start:i-1);% the previous episode data
        ix(k) = v(i-1);% sleep stage of the previous episode

        % Update segment position and count
        segment_start = i;
        k = k+1;
    end
end

% Store the last segment and sleep stage
segments{end+1} = v(segment_start:end);
ix(k) = v(end);
end
