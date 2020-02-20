function result = custom_analysis( eXT, analyseAll )
    %% This method stub should be written by the user. 
	%  The user recceives a handle to EasyXT (eXT) through which 
	%  they can access all the objects from the Imaris Scene and compute
	%  a measurement.
	%  the analyseAll object is a reference to the EasyXT_GUI 'Analyze All'
	%  command. It could be useful to run this command before getting statistics
	%  or other objects as it happens that Imaris sometimes doens't refresh things
	%  most of the time you can ignore it.
	% The output 'result' is a Matlab table that should contain the columns and rows
	% that this script will have computed. The image name will be automatically added
	% by EasyXT_GUI. This will then be saved as a CSV file by EasyXT_GUI at the end 
	% of the processing.
 
    result = table();
	
    % This simple example shows how to get the total number of Imaris Spots 
    % in the dataset
    
	result.Channels = eXT.GetSize('C');
	result.Slices = eXT.GetSize('Z');
    
    % Get the number of 'Spots' Objects, not the number of spots per object
	nSpots = eXT.GetNumberOf('Spots');
    
    if nSpots > 0
        spot = eXT.GetObject('Type', 'Spots', 'Number', 1);
        % Strings should be as cell arrays. It's a Matlab thing, I think
        result.SpotName = {eXT.GetName(spot)};
    end
    
    result.nSpots = nSpots;
    
    % A More detailed example showing how to get the mean intensity for
    % each spot in a given channel
    result = table();
    
    if nSpots > 0
        spot = eXT.GetObject('Type', 'Spots', 'Number', 1);
        stats = eXT.GetSelectedStatistics(spot, 'Intensity Mean', 'Channel', 3);
        % Strings should be as cell arrays. It's a Matlab thing, I think
        result.SpotID = stats.ids;
        result.Ch3Mean = stats.values;
    end
    
    
    
end