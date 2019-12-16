%% This whole part handles creating the interface and the logic
function EasyXT_GUI(gui_name, af)
%Start EasyXT
addpath('EasyXT');
global X;
global analysis_function;

X = EasyXT(); 
analysis_function = af;

f = figure('Name', sprintf('BIOP - %s', gui_name), ...
    'NumberTitle', 'off', 'Visible', 'off', 'Position', [0 0 600 512], ...
    'Tag', 'main_f', ...
    'DockControls', 'off', 'ToolBar', 'none', 'MenuBar', 'none');

% Move the window to the center of the screen.
movegui(f,'center')

% Make the window visible.
f.Visible = 'on';

% Add 1 panel on the left and one on the right
settingsp = uipanel(f,'Title','Settings', 'Tag', 'p_settings',...
    'Position',[.05 .05 .70 .9]);

commandsp = uipanel(f,'Title','Actions', 'Tag', 'p_commands',...
    'Position',[.75 .05 .20 .9]);

% Settings Tab
uitabgroup('Parent', settingsp, 'Tag', 'tab_channels');

% Add buttons for refreshing data, and batch
h = .15;
w = .8;
l = .1;

uicontrol(commandsp,'Style','pushbutton','String','Refresh',...
    'Units','normalized', 'Tag', 'btn_refresh', ...
    'Position',[l .80 w h],...
    'Callback', @refreshbtn_callback);
uicontrol(commandsp,'Style','pushbutton','String','Detect All',...
    'Units','normalized', 'Tag', 'btn_detect', ...
    'Position',[l .65 w h],...
    'Callback', @detectbtn_callback);
uicontrol(commandsp,'Style','pushbutton','String','Analyze',...
    'Units','normalized', 'Tag', 'btn_analyze', ...
    'Position',[l .50 w h],...
    'Callback', @analyzebtn_callback);

uicontrol(commandsp,'Style','pushbutton','String','Batch Process',...
    'Units','normalized', 'Tag', 'btn_batch', ...
    'Position',[l .35 w h],...
    'Callback', @batchbtn_callback);

uicontrol(commandsp,'Style','text',...
    'String','Settings',...
    'Units','Normalized', ...
    'HorizontalAlignment', 'center', ...
    'Position',[l .17 w 0.05]);

uicontrol(commandsp,'Style','pushbutton','String','Save',...
    'Units','normalized', 'Tag', 'btn_save', ...
    'Position',[l .10 w/2 h/2],...
    'Callback', @savebtn_callback);

uicontrol(commandsp,'Style','pushbutton','String','load',...
    'Units','normalized', 'Tag', 'btn_load', ...
    'Position',[l+w/2 .10 w/2 h/2],...
    'Callback', @loadbtn_callback);

uicontrol(commandsp,'Style','checkbox','String','Append Results',...
    'Units','normalized', 'Tag', 'is_append', ...
    'Position',[.1 0 .8 .1]);


refreshFromIms();

end

% Refreshes the interface by taking in the number of channels
function refreshFromIms()
global X;
tgroup = findobj('Tag','tab_channels');

% Get the number of channels
% Make a menu for each channel where the user can select wether it's meant
% to detect surfaces or spots or nothing.
nChan = X.GetSize('C');
%nChan = 5;

for i=1:nChan
    %Build interface
    aTab = findobj('Tag',sprintf('tab_c%d',i));
    if isempty(aTab)
        thisTab(i) = uitab('Parent', tgroup, 'Title', sprintf('Channel %d',i), ...
            'Tag', sprintf('tab_c%d',i), 'UserData', i);
        
        uicontrol(thisTab(i),'Style','text',...
            'String','Name',...
            'Units','Normalized', ...
            'HorizontalAlignment', 'right', ...
            'Position',[0 0.925 .1 0.05]);
        
        uicontrol(thisTab(i), 'Style', 'edit', 'String', sprintf('Channel %d', i), ...
            'Tag', sprintf('c%dname',i), ...
            'Units','Normalized', ...
            'Position',[0.11 0.925 .3 0.05]);
        
        
        %Add choice to detect spots or surfaces then add panel with options
        detection_method = uibuttongroup('Parent', thisTab(i), 'Position',[0 .80 1 .10],...
            'Tag', sprintf('detect_choice_c%d',i), ...
            'SelectionChangedFcn',@detection_method_change);
        radioSpots = uicontrol(detection_method,'Style',...
            'radiobutton',...
            'String','Detect Spots', 'Tag', sprintf('spotsc%d',i), ...
            'Position', [10 5 100 30]);
        
        radioSurfaces = uicontrol(detection_method,'Style',...
            'radiobutton',...
            'String','Detect Surfaces', 'Tag', sprintf('surfc%d',i), ...
            'Position', [110 5 100 30]);
        
        radioNone = uicontrol(detection_method,'Style',...
            'radiobutton',...
            'String','Do Not Use', 'Tag', sprintf('notc%d',i), ...
            'Position', [210 5 100 30]);
        % By default create a spot detection interface
        spot_panel(i) = createSpotDetectionInterface(i);
        spot_panel(i).Parent = thisTab(i);
        
        surf_panel(i) = createSurfaceDetectionInterface(i);
        surf_panel(i).Parent = thisTab(i);
        surf_panel(i).Visible = 'off';
    end
    
end

end

% When the user clicks on either 'Detect Spots' or 'Detect Surfaces'
% it builds the necessary menu if it was not already creates and handles
% hiding menus we do not want to see.
function detection_method_change(hObject, eventdata, handles)
% Get channel
c = hObject.Parent.UserData;
spot_panel = findobj('Tag',sprintf('spot_panel_c%d',c));
surface_panel = findobj('Tag',sprintf('surface_panel_c%d',c));

event = get(eventdata.NewValue,'Tag');
%trim before the c#
idx = strfind(event,'c');
event = event(1:idx-1);
switch event % Get Tag of selected object.
    case 'spots'
        display(sprintf('Detect Spots for channel %d',c));
        if ~isempty(surface_panel)
            surface_panel.Visible = 'off';
        end
        
        if isempty(spot_panel)
            % Make Spot Detection Interface
            spot_panel = createSpotDetectionInterface(c);
            spot_panel.Parent = hObject.Parent;
        end
        
        spot_panel.Visible = 'on';
        
    case 'surf'
        display(sprintf('Detect Surfaces for channel %d',c));
        if ~isempty(spot_panel)
            spot_panel.Visible = 'off';
        end
        
        if isempty(surface_panel)
            % Make Surface Detection Interface
            surface_panel = createSurfaceDetectionInterface(c);
            surface_panel.Parent = hObject.Parent;
        end
        surface_panel.Visible = 'on';
        
    case 'not'
        if ~isempty(surface_panel)
            surface_panel.Visible = 'off';
        end
        if ~isempty(spot_panel)
            spot_panel.Visible = 'off';
        end
end
end

% The Spots interface for each channel
function spot_panel = createSpotDetectionInterface(c)
% make a panel
spot_panel = uipanel('Title','Spot Detection', 'Tag', sprintf('spot_panel_c%d',c),...
    'Position',[0 0 1 .8]);
% add options

leftx   = .01;
leftxm  = .18;
rightx  = .35;
rightxm = rightx+0.27;
elh     = .06;

top = .9;
step= 0.08;

uicontrol(spot_panel,'Style','text',...
    'String','Smoothing',...
    'Units','Normalized', ...
    'HorizontalAlignment', 'right', ...
    'Position',[leftx top .16 elh]);
uicontrol(spot_panel, 'Style', 'edit', 'String', '0.1', ...
    'Tag', sprintf('spotc%dsmooth',c), ...
    'Units','Normalized', ...
    'Position',[leftxm top .07 elh]);

uicontrol(spot_panel,'Style','text',...
    'String','Spot Size XY',...
    'Units','Normalized', ...
    'HorizontalAlignment', 'right', ...
    'Position',[rightx top .25 elh]);

uicontrol(spot_panel, 'Style', 'edit', 'String', '10', ...
    'Tag', sprintf('spotc%dxy',c), ...
    'Units','Normalized', ...
    'Position',[rightxm top .07 elh]);

uicontrol(spot_panel, 'Style', 'checkbox', 'String', 'Detect Ellipsoid', ...
    'Tag', sprintf('spotc%disz',c), ...
    'Units','Normalized', ...
    'Position',[rightxm+0.08 top-step .25 elh]);

uicontrol(spot_panel,'Style','text',...
    'String','Spot Size Z',...
    'Units','Normalized', ...
    'Position',[rightx top-step .25 elh]);

uicontrol(spot_panel, 'Style', 'edit', 'String', '0.1', ...
    'Tag', sprintf('spotc%dz',c), ...
    'Units','Normalized', ...
    'HorizontalAlignment', 'right', ...
    'Position',[rightxm top-step .07 elh]);

%Add thresholds for quality and checkbox
uicontrol(spot_panel,'Style','text',...
    'String','Quality',...
    'Units','Normalized', ...
    'HorizontalAlignment', 'right', ...
    'Position',[leftx top-step .16 elh]);

uicontrol(spot_panel, 'Style', 'edit', 'String', '10', ...
    'Tag', sprintf('spotc%dquality',c), ...
    'Units','Normalized', ...
    'Position',[leftxm top-step .07 elh]);

uicontrol(spot_panel, 'Style', 'checkbox', 'String', 'Auto', ...
    'Tag', sprintf('spotc%disqualityauto',c), ...
    'Units','Normalized', ...
    'Position',[leftxm+0.08 top-step .11 elh]);

%Add threshold for region growing and auto checkbox
uicontrol(spot_panel, 'Style', 'checkbox', 'String', 'Perform Region Growing', ...
    'Tag', sprintf('spotc%disgrowing',c), ...
    'Units','Normalized', ...
    'Position',[leftx+0.05 top-3*step .50 elh]);

uicontrol(spot_panel,'Style','text',...
    'String','Threshold',...
    'Units','Normalized', ...
    'HorizontalAlignment', 'right', ...
    'Position',[leftx top-4*step .16 elh]);

uicontrol(spot_panel, 'Style', 'edit', 'String', '10', ...
    'Tag', sprintf('spotc%dthrgrowing',c), ...
    'Units','Normalized', ...
    'Position',[leftxm top-4*step .07 elh]);

uicontrol(spot_panel, 'Style', 'checkbox', 'String', 'Auto', ...
    'Tag', sprintf('spotc%disthrgrowingauto',c), ...
    'Units','Normalized', ...
    'Position',[leftxm+0.08 top-4*step .11 elh]);

% Button for testing
uicontrol(spot_panel,'Style','pushbutton','String','Test Spot Parameters',...
    'Units','normalized', 'Tag', sprintf('btn_testc%d',c), ...
    'Position',[.1 .10 .8 .2],...
    'Callback', {@testspot_callback, c});

end

% The Surface creation interface for each channel
function surface_panel = createSurfaceDetectionInterface(c)
% make a panel
surface_panel = uipanel('Title','Surface Detection', 'Tag', sprintf('surface_panel_c%d',c),...
    'Position',[0 0 1 .8]);

leftx   = .01;
elh     = .06;
txtw    = .3;
elw     = .07;
top = .9;
step= 0.08;

% SMOOTHING
uicontrol(surface_panel,'Style','text',...
    'String','Smoothing',...
    'Units','Normalized', ...
    'HorizontalAlignment', 'right', ...
    'Position',[leftx top txtw elh]);
uicontrol(surface_panel, 'Style', 'edit', 'String', '0.1', ...
    'Tag', sprintf('surface%dsmooth',c), ...
    'Units','Normalized', ...
    'Position',[leftx+txtw top elw elh]);

% THRESHOLD
uicontrol(surface_panel, 'Style', 'checkbox', 'String', 'Auto', ...
    'Tag', sprintf('surface%dthrisauto',c), ...
    'Units','Normalized', ...
    'Position',[leftx+txtw+0.08 top-step txtw elh]);

uicontrol(surface_panel,'Style','text',...
    'String','Surface Threshold',...
    'Units','Normalized', ...
    'HorizontalAlignment', 'right', ...
    'Position',[leftx top-step txtw elh]);

uicontrol(surface_panel, 'Style', 'edit', 'String', '0.1', ...
    'Tag', sprintf('surface%dithr',c), ...
    'Units','Normalized', ...
    'Position',[leftx+txtw top-step elw elh]);

% Local Contrast
uicontrol(surface_panel, 'Style', 'checkbox', 'String', 'Use Local Contrast', ...
    'Tag', sprintf('surface%dthrislocalcontrast',c), ...
    'Units','Normalized', ...
    'Position',[leftx+txtw+0.08 top-2*step txtw elh]);

uicontrol(surface_panel,'Style','text',...
    'String','Largest sphere',...
    'Units','Normalized', ...
    'HorizontalAlignment', 'right', ...
    'Position',[leftx top-2*step txtw elh]);

uicontrol(surface_panel, 'Style', 'edit', 'String', '0.1', ...
    'Tag', sprintf('surface%dlocsphere',c), ...
    'Units','Normalized', ...
    'Position',[leftx+txtw top-2*step elw elh]);



% Add Size Filter
uicontrol(surface_panel,'Style','text',...
    'String','Min Volume',...
    'Units','Normalized', ...
    'HorizontalAlignment', 'right', ...
    'Position',[leftx top-3*step txtw elh]);

uicontrol(surface_panel, 'Style', 'edit', 'String', '1e3', ...
    'Tag', sprintf('surface%dsizethr',c), ...
    'Units','Normalized', ...
    'Position',[leftx+txtw top-3*step elw elh]);

uicontrol(surface_panel,'Style','text',...
    'String','um^3',...
    'Units','Normalized', ...
    'HorizontalAlignment', 'left', ...
    'Position',[leftx+txtw+0.08 top-3*step txtw elh]);

%Add threshold for region growing and auto checkbox
uicontrol(surface_panel, 'Style', 'checkbox', 'String', 'Perform Region Growing', ...
    'Tag', sprintf('surface%disgrowing',c), ...
    'Units','Normalized', ...
    'Position',[leftx+0.08 top-4*step .50 elh]);

% SEED DIAMETER
uicontrol(surface_panel,'Style','text',...
    'String','Seed Diameter',...
    'Units','Normalized', ...
    'HorizontalAlignment', 'right', ...
    'Position',[leftx top-5*step txtw elh]);

uicontrol(surface_panel, 'Style', 'edit', 'String', '10', ...
    'Tag', sprintf('surface%dseeddiam',c), ...
    'Units','Normalized', ...
    'Position',[leftx+txtw top-5*step .07 elh]);

% SEED Quality
uicontrol(surface_panel, 'Style', 'checkbox', 'String', 'Auto', ...
    'Tag', sprintf('surface%disseedfilterauto',c), ...
    'Units','Normalized', ...
    'Position',[leftx+txtw+0.08 top-6*step txtw elh]);

uicontrol(surface_panel,'Style','text',...
    'String','Quality',...
    'Units','Normalized', ...
    'HorizontalAlignment', 'right', ...
    'Position',[leftx top-6*step txtw elh]);

uicontrol(surface_panel, 'Style', 'edit', 'String', '10', ...
    'Tag', sprintf('surfacec%dregionquality',c), ...
    'Units','Normalized', ...
    'Position',[leftx+txtw top-6*step .07 elh]);


% Button for testing
uicontrol(surface_panel,'Style','pushbutton','String','Test Parameters',...
    'Units','normalized', 'Tag', sprintf('btn_testsurfc%d',c), ...
    'Position',[.1 .10 .8 .2],...
    'Callback', {@testsurface_callback, c});
end

% Action when the Test Spots Parameters button is pressed
function testspot_callback(~, eventdata, channel)
makeSpots(channel);
end

function testsurface_callback(hObject, eventdata, channel)
%Get the channel
makeSurfaces(channel);
end

% Action when the 'Refresh' button is pressed
% Makes sure to re-read the number of channels on the dataset
function refreshbtn_callback(hObject, eventdata, handles)
refreshFromIms()
end

% Action when the 'Detect All' button is pressed
% This runs the detection for each desired object
function detectbtn_callback(hObject, eventdata, handles)
detectAll();
end

% Action when the 'Detect All' button is pressed
% This runs the detection for each desired object
function analyzebtn_callback(hObject, eventdata, handles)
analyzeImage();
end

% Action when the 'Batch Process' button is pressed
% This prompts for a folder and runs all the other nice stuff
function batchbtn_callback(hObject, eventdata, handles)
runBatch();
end

% Action when the 'Batch Process' button is pressed
% This prompts for a folder and runs all the other nice stuff
function loadbtn_callback(hObject, eventdata, handles)
loadSettings();
end

% Action when the 'Batch Process' button is pressed
% This prompts for a folder and runs all the other nice stuff
function savebtn_callback(hObject, eventdata, handles)
saveSettings();
end

%% Settings saving and loading functions
function loadSettings()
[FileName,PathName,FilterIndex] = uigetfile('*.m','Load Settings');
D = load([PathName FileName], '-mat');
if ~isfield(D,'data')
    return
end

% Restore all you got
f = findobj('Tag', 'main_f');
%Edit buttons
txt = findall(f, 'Style', 'edit');
chk = findall(f, 'Style', 'checkbox');
rad = findall(f, 'Style', 'radiobutton');
controls = [txt; chk; rad];

for i=1:numel(D.data)
    obj = findobj('Tag', D.data(i).tag);
    if ~isempty(obj)
        if ~isempty(D.data(i).string)
            obj.String = D.data(i).string;
        end
        if ~isempty(D.data(i).value)
            obj.Value = D.data(i).value;
        end
        
        obj.Visible = D.data(i).visible;
    end
    
end


end

function saveSettings()
% Controls we need to save are 'edit', 'checkbox', 'radio'
% so go through all of them and save them in a cell array with the tag and
% the value or string
f = findobj('Tag', 'main_f');
%Edit buttons
txt = findall(f, 'Style', 'edit');
chk = findall(f, 'Style', 'checkbox');
rad = findall(f, 'Style', 'radiobutton');

controls = [txt; chk; rad];
data = struct();

for i=1:numel(controls)
    data(i).tag = controls(i).Tag;
    data(i).string = controls(i).String;
    data(i).value = controls(i).Value;
    data(i).visible = controls(i).Visible;
end

% Panel Visibility
spp = findobj('-regexp','Tag','spot_panel.*');
srp = findobj('-regexp','Tag','surface_panel.*');
panels = [spp; srp];
for i=1:numel(panels)
    data(numel(controls)+i).tag = panels(i).Tag;
    data(numel(controls)+i).visible = panels(i).Visible;
end
data
% Save this somewhere
[FileName,PathName,FilterIndex] = uiputfile('saved-settings.m','Save Settings');
save([PathName FileName],'data');
end



%% Functions that create the spots and interact with Imaris

% Make spots for the given channel
function makeSpots(c)
global X;
% Get all parameters
smoothing = str2num(get(findobj('Tag', sprintf('spotc%dsmooth',c)), 'String'));
quality   = str2num(get(findobj('Tag', sprintf('spotc%dquality',c)), 'String'));
xy = str2num(get(findobj('Tag', sprintf('spotc%dxy',c)), 'String'));
z = str2num(get(findobj('Tag', sprintf('spotc%dz',c)), 'String'));
regionthr = str2num(get(findobj('Tag', sprintf('spotc%dthrgrowing',c)), 'String'));

isqualityauto = (get(findobj('Tag', sprintf('spotc%disqualityauto',c)),'Value'));

isregiongrowing = (get(findobj('Tag', sprintf('spotc%disgrowing',c)),'Value'));

isregionthrauto = (get(findobj('Tag', sprintf('spotc%disthrgrowingauto',c)),'Value'));

chanName = get(findobj('Tag', sprintf('c%dname',c)), 'String');
name = sprintf('Spots from %s',chanName);


if (isregionthrauto)
    regionthr = 'Auto';
end
if(isqualityauto)
    filter = '"Quality" above automatic threshold';
else
    filter = sprintf('"Quality" above %.2f', quality);
end

isellipse = get(findobj('Tag', sprintf('spotc%disz',c)),'Value');

theSpot = X.GetObject('Name', name);

% Create the name of the thing we are making
if(~isempty(theSpot))
    X.RemoveFromScene(theSpot);
end

theSpot = X.DetectSpots(c,'Name', name, 'Diameter XY', xy, 'Diameter Z', z, 'Subtract BG', true, ...
    'Region Growing Threshold', regionthr, 'Region Growing', isregiongrowing, 'Detect Ellipse', isellipse, ...
    'Spots Filter', filter);
X.AddToScene(theSpot);
end

% Make surfaces for the given channel
function makeSurfaces(c)

global X;

% Get all parameters
smoothing = str2num(get(findobj('Tag', sprintf('surface%dsmooth',c)), 'String'));

is_surf_i_auto     = (get(findobj('Tag', sprintf('surface%dthrisauto',c)),'Value'));
is_local_contrast     = (get(findobj('Tag', sprintf('surface%dthrislocalcontrast',c)),'Value'));
loc_contrast_sphere      = str2num(get(findobj('Tag', sprintf('surface%dlocsphere',c)), 'String'));

intensity_thr      = str2num(get(findobj('Tag', sprintf('surface%dithr',c)), 'String'));
min_volume_filter  = str2num(get(findobj('Tag', sprintf('surface%dsizethr',c)), 'String'));

is_surf_region_growing = (get(findobj('Tag', sprintf('surface%disgrowing',c)),'Value'));
seed_diameter = str2num(get(findobj('Tag', sprintf('surface%dseeddiam',c)), 'String'));

is_seed_filter_auto     = (get(findobj('Tag', sprintf('surface%disseedfilterauto',c)),'Value'));
seed_quality_filter = str2num(get(findobj('Tag', sprintf('surfacec%dregionquality',c)), 'String'));

chanName = get(findobj('Tag', sprintf('c%dname',c)), 'String');
name = sprintf('Surfaces from %s',chanName);

% Now run surface detection

% Smoothing auto means that smoothing should be set to 0
if is_surf_i_auto
    intensity_thr = 0;
end

if ~is_local_contrast
    loc_contrast_sphere = 0;
end

if is_seed_filter_auto
    seed_filter = '"Quality" above automatic threshold';
else
    seed_filter = sprintf('"Quality" above %.2f', seed_quality_filter);
    
end

volume_filter = sprintf('"Volume" above %.2f um^3', min_volume_filter);


% Create the name of the thing we are making
thesurf = X.GetObject('Name', name);
if(~isempty(thesurf))
    X.RemoveFromScene(thesurf);
end

thesurf = X.DetectSurfaces(c,'Name', name, 'Smoothing', smoothing, 'Local Contrast', loc_contrast_sphere, 'Threshold', intensity_thr, ...
    'Filter', volume_filter, ...
    'Seed Local Contrast', true, 'Seed Filter', seed_filter, 'Seed Diameter', seed_diameter, ...
    'Split', is_surf_region_growing);
X.AddToScene(thesurf);
end

% Run the detection on everything
function detectAll()
global X;

%Get the number of channels
nChan = X.GetSize('C');

% Check what kind of processing to do
for i = 1:nChan
    %Get the tab matching the channel
    toDetect = get(findobj('Tag', sprintf('detect_choice_c%d',i)),'SelectedObject');
    event = get(toDetect,'Tag');
    %trim before the c#
    idx = strfind(event,'c');
    event = event(1:idx-1);
    if ~isempty(idx) % Fixes issue where number of channels changed due to analysis...
        switch event % Get Tag of selected object.
            case 'spots'
                display(sprintf('Detect Spots for channel %d',i));
                makeSpots(i);
            case 'surf'
                display(sprintf('Detect Surfaces for channel %d',i));
                makeSurfaces(i);
            case 'not'
                display(sprintf('Do Nothing for channel %d',i));
        end
    
    end
end
end

function analyzeImage()
global X;
global analysis_function;

fileDir =[];

[fileDir fileName ext] = X.GetCurrentFileName();

nChan = X.GetSize('C');

%append name of analysis function to the filename
funcData = functions( analysis_function);
funcName = funcData.function;

is_append = (get(findobj('Tag', 'is_append'),'Value'));



results = analysis_function(X, @detectAll);


% Compatibility. If it is just one result, make it into a cell array
if istable( results )
    results = {results};
end

nResults = numel( results );
for k = 1:nResults
    result = results{k};
    sheetName = [];
    data = [];
    % Append Image name as column
    result.Image = repmat({fileName}, size(result,1),1);
    
    resultsName = [funcName '-analysis.xlsx'];
    
    % Try and find this file and see if we need to append or not
    if is_append
        file = [ '/' resultsName ];
    else
        file = [ '/' fileName '-' resultsName ];
    end
    filePath = [fileDir file]; 

    if ~isempty(result.Properties.UserData)
        sheetName = result.Properties.UserData;
    end
    
    % If it exists, load the existing data
    if exist(filePath, 'file') == 2 && is_append
        % Read in the data
            % Get desired file name from properties
            % This does not work if the sheet does not exist, which happens
            % the first time the file is created
            % Check that it exists first
            
            [name sheetNames] = xlsfinfo(filePath);
            if any(ismember(sheetNames, sheetName))
                data = readtable(filePath, 'Sheet', sheetName);
            else
                data = table;
            end
    else
        % This is the first time
        data = table;
    end
    
    data = [data; result];
    
    if ~isempty(sheetName)
        writetable(data,filePath, 'Sheet', sheetName);
    else
        writetable(data,filePath);
    end
end
end

% Helps match surface names
function [surfIdx, subSurfIdx] = findSurfaceIndex(spotName, surface_names)
surfIdx  =-1;
% spotName structure 'SPOT NAME inside SURF NAME [SubSurfIDX]'
[tok] = regexp(spotName, '(.*) inside (.*) \[(\d)\]', 'tokens');
subSurfIdx = str2num(tok{1}{3});
surfName = tok{1}{2};
for i=1:numel(surface_names)
    sprintf('surface name: %s',surfName);
    if strcmp(surfName, surface_names{i})
        surfIdx = i;
    end
end


end


% Function for running everything in batch
function runBatch()
global X;
X = EasyXT;

%Get the starting path for the directory
lastImgPath = X.GetCurrentFileName();

% Ask for the directory
batchPath = uigetdir(lastImgPath, 'Choose Folder with files to batch process')
files = dir( fullfile(batchPath) ); % List the files
files = {files.name}'; % Keep only the name as a Cell Array
saveDir = [batchPath,'/Results/'];

mkdir(saveDir);

% Check for files that already exist
processedFiles = dir(saveDir);
processedFileNames = {processedFiles.name}';

% Go through the files
for i = 1:numel(files)
    file = files{i}
    X.isImage(file)
    if X.isImage(file) && ~strcmp('.',file) &&  ~strcmp('..',file)
        disp([file ' is an image']);
        if ~ismember([file,'.ims'], processedFileNames)
            X.OpenImage(fullfile(batchPath, file));
            refreshFromIms();
            % Run the processing
            detectAll();
            analyzeImage();
            fullfile(saveDir, file)
            X.ImarisApp.FileSave([fullfile(saveDir, file) '.ims'],'');

            pause(2);
        else 
            sprintf('File %s already processed', file)
        end
        
    end
end

end
