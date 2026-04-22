function [out,meanPatient]=get_average_data(data)
% Purpose: Get the average probability of each subject and across all subjects
% data: 0/1 sleep stage data
% out: the average probability across all subjects
% meanPatient: accumulated average probability of each subject
% row(M): each subject, column: bin(30s)

% Initiate an empty array to store the average probability of each subject
meanPatient = [];

% Loop through each subject data
for i = 1:size(data,1)
    Patient = data{i, 1}'; % Extract one subject data
    meanPatient = catpad(1,meanPatient,mean(Patient,1,'omitmissing'));% Calculate average probability of each subject
end

out = mean(meanPatient,1,'omitmissing');% Calculate the average probability across all subjects





