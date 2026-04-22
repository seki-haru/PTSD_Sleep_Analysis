function v_reconstructed=segment2vector(segments)
% Purpose: Combine data segments again
% segments: data segments of 0/1 episodes
% v_reconstructed: 0/1 sleep stage data for one night

% Initialize an empty array to store 0/1 sleep stage data for one night
v_reconstructed = [];

% Combine data segments
for i = 1:length(segments)
    v_reconstructed = [v_reconstructed, segments{i}'];
end

end


