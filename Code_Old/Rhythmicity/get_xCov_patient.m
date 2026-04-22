function [out,X]=get_xCov_patient(meanPatient)
% Purpose: Get the autocorrelation of average probability of each subject
% meanPatient: accumulated average probability of each subject
% out: accumulated autocorrelation of average probability of each subject
% X: accumulated shifted bin numbers of each subject
% row: each subject, column: bin (30s)

% Initiate an empty array to store the autocorrelation of average probability of each subject
out = [];
% Initiate an empty array to store shifted bin numbers of each subject
X = [];

% Loop through each subject data
for i = 1:size(meanPatient,1)
    t = meanPatient(i,:);% Extract average probability of one subject
    t(isnan(t)) = [];

    [temp,x] = xcov(t,'coeff');% Get autocorrelation of the probability
    % temp: autocorrelation, x: shifted bin numbers

    % Delete negative values
    temp(x<0) = [];
    x(x<0) = [];

    % Accumulate the autocorrelations and shifted bin numbers across all subjects
    out = catpad(1,out,temp);
    X = catpad(1,X,x);
end