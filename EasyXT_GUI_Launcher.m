addpath('functions');
addpath('EasyXT');

% This  launches the GUI with the selected title
% The second argument is the handle to the matlab script that will 
% process the data and generate a table output
EasyXT_GUI('EasyXT GUI - Detect And Analyze', @custom_analysis);
