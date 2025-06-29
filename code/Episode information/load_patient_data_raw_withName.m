function [T,N]=load_patient_data_raw_withName(folderName)
% Purpose: Load all subjects sleep data
% folderName = 'Healthy' or 'PTSD'
% T: sleep stage data by numeric values
% one subject data in each cell
% one cell data > row: bin (30s), column: each night
% 0==Wake, 1==N1, 2==N2, 3==N3, 4==R, 5==NotScored
% N: subject IDs (column1) and their recording IDs (column2)


% Get the current working directory
currentDir = pwd;

% Combine the current directory with the folder name
folderPath = fullfile(currentDir, folderName);
folders = get_folders_list(folderPath); % Get subject IDs

% Initiate an empty array to store ID information
N = [];

% Loop through each subject folder
for i = 1:size(folders,2)
    % Get a path of the subject folder
    NightPath = fullfile(folderPath, folders(i));
    
    N{i,1} = folders(i); % Store the subject ID
    [T{i,1},N{i,2}] = get_data_each_patient(NightPath); % Get sleep stage data for the subject and store recording IDs
end

N(:,1) = cellfun(@(x) x{1}, N(:,1), 'UniformOutput', false);

end



function folders=get_folders_list(folderPath)

contents = dir(folderPath);

% Initialize an empty cell array to store folder names
folders = {};

% Store the folder name to the cell array
for i = 1:length(contents)
    % Check if the item is a directory and not '.' or '..'
    if contents(i).isdir && ~strcmp(contents(i).name, '.') && ~strcmp(contents(i).name, '..')
        folders{end+1} = contents(i).name;
    end
end

end



function [T,N]=get_data_each_patient(NightPath)

files = dir(fullfile(NightPath{:},filesep, '*.csv'));

% Initialize a main structure to store sleep stage data
T = [];
% Initialize an empty array to store recording IDs
N = [];

% Loop through each CSV file
for fileIndex = 1:length(files)

    fileName = files(fileIndex).name;% Get the file name
    parts = split(extractBefore(fileName, '.csv'), '_');
    N{end+1} = parts{2}; % Store the recording ID

    % Construct the full file path of the CSV file
    filePath = fullfile(NightPath{:}, fileName);    
    data = readtable(filePath,'VariableNamingRule', 'preserve'); % Load the CSV file into a table
    
    numericVector = table2hypno(data); % Replace sleep names to numeric values
    T = catpad(2,T,numericVector);
end

end

function numericVector=table2hypno(data)

sleepStagesCellArray=data{:,3};% Extract the sleep stage data column
% Initialize a numeric vector to store the converted values
numericVector = zeros(size(sleepStagesCellArray));

% Define mappings from stage names to numeric values
stageMap = containers.Map(...
    {'Wake', 'WK', 'NonREM1', 'N1', 'NonREM2', 'N2', 'NonREM3', 'N3', 'REM', 'R', 'NotScored', 'NS'}, ...
    {0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5});

% Convert each stage to its numeric equivalent
for i = 1:numel(sleepStagesCellArray)
    stage = sleepStagesCellArray{i};

    if isKey(stageMap, stage)
        numericVector(i,1) = stageMap(stage);
    else
        numericVector(i,1) = NaN; % If the stage is not found in the map, assign NaN
    end
end

end