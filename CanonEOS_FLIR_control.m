%% Example Camera and PTU-5 integration
% This code integrates control of the Canon EOS 6D and the FLIR PTU-5

% The camera begins at 0 degrees and takes a series of photos. After photo
% capture is complete, the FLIR PTU-5 rotates the camera 90 degrees CW and
% the camera captures another series of photos. 

% The PTU-5 returns the camera to home and the process is repeated for each
% louver angle / room configuration

%% FLIR PTU-5 Set-up
% Find a serial port object.
obj1 = instrfind('Type', 'serial', 'Port', 'COM4', 'Tag', ''); % <------- Update COM port #

% Create the serial port object if it does not exist
% otherwise use the object that was found.
if isempty(obj1)
    obj1 = serial('COM4');                                     % <------- Update COM port #
else
    fclose(obj1);
    obj1 = obj1(1);
end

% Connect to instrument object, obj1.
fopen(obj1);

% Configure instrument object, obj1.
set(obj1, 'BaudRate', 9600);
set(obj1, 'DataBits', 8);
set(obj1, 'FlowControl', 'none');
set(obj1, 'Parity', 'none');
set(obj1, 'StopBits', 1.0);

%% Set the PTU-5 parameters

% Return pan and tilt position to Home:
fprintf(obj1, 'pp0 ');
fscanf(obj1);

fprintf(obj1, 'tp0 ');
fscanf(obj1);

% Set the absolute speed in position/sec:
fprintf(obj1, 'ps4500 ');       % 90 degrees in 2 seconds
fscanf(obj1);

%% Camera Setup
% The Basics:
%1.Install and start digiCamControl
%2.Open digiCamControl and enable webserver by going to File>Settings>Webserver>Enable> RESTART APP
%3.Connect one or more cameras using USB cable
%4.Set camera to (M) and lens to (MF)
%5.Use digiCamControl app to ensure camera is working. Camera name will
% appear in the dropdown menus in the top left corner of the screen

% Troubleshooting:
%1. DigiCamControl can't find the camera
%   Make sure the camera is powered on and not in sleep mode. If the camera
%   goes to sleep, digiCamControl will not be able connect to it.  

%% Initializing digiCamControl

C = CameraController; %initialise

%% Camera transfer settings: 

% It's best to set "Transfer" mode in the GUI
% Open DigiCamControl and set to "Save to PC and the camera memory card"

% DON'T delete file after transfer:
C.session.deletefileaftertransfer = 0;  % only has affect if Transfer="Cam+PC" 
                                        % and affectively converts it to "PC only"
                                        % when set to True
% DON'T download only the JPG:                                       
C.session.downloadonlyjpg = 0;          % only used if "PC+CAM"
                                        
% DON'T ask for the path:                                       
C.session.asksavepath = 0;              % dialogue pop-up for after capture

% DON'T allow file overwrite:
C.session.allowoverwrite = 0;           % overwrite if file exists

% DO use lower case:
C.session.lowercaseextension = 1;       % use "*.jpg" instead of "*.JPG"

C.session.downloadthumbonly = 0;        % not working (v2.0.72.9)

%% Set the camera parameters

C.session.useoriginalfilename = 0;    % Ignores "filenametemplate"
                                      % this is necessary otherwise the program will revert to default
                                      
% % Export as Large RAW file:                                    
% C.camera.compressionsetting = 'Raw';  % Could just set this up on the camera                                 

% ISO number:
C.camera.isonumber = 100;

% Aperture:
C.camera.fnumber = 10;

% Set the session name
% I'm honestly not sure if this is important or not
C.session.name = 'EcoTekTesting';

% Room configuration:
roomdistance = 'x';                % <-- Probably will have to be user input
roomangle = 'y';                   % <-- Probably will have to be user input

% Louvered blinds angle:
louver = [1:3];

% Shutter speeds:
shutterspeed = {('1/1000'),('1/500'),('1/250'),('1/125'),('1/60'),('1/30'),...
    ('1/15'),('1/8'),('1/4'),('0.5'),('1'),('2'),('4'),('8'),('15')};

%% Capture the photos and rotate 90 degrees

% Filepath:
directory = 'C:\Users\mksylvia\Pictures\FrontierTesting\';     % <--- Update

for i = 1:size(louver,2)  % Cycle through the louver angles
    
    % Create a folder to store the photos. 
    % Format is 'Roomxy_Louver#'
    filename = strcat('Room',roomdistance,roomangle,'_Louver',num2str(louver(i)));
    filepath = strcat(directory,filename);
    
    for j = 1:2   % Cycle through the camera positions ( +/- 90 degrees)
        
        camera_pos = [0 90];
        
        % Make a folder within the current folder on the filepath
        % Format is Roomxy_Louver#\Camera#deg
        
        foldername = strcat('Camera',num2str(camera_pos(j)),'degrees');
        folderpath = strcat(filepath,'\',foldername);
        
        % Tell digiCam to save the photos to the specific folder:
        C.session.folder = folderpath;
        
        
        for k = 1:size(shutterspeed,2) % Cycle through the shutter speeds

            % Specify the filename for each photo. 
            % Format is 'Roomxy_Louver#_#deg_shuterspped#'
            % note: it's necessary to replace the / in the fraction with an _
            imagename = strcat(filename,'_',num2str(camera_pos(j)),'deg_exp',strrep(shutterspeed{k},'/','_'));

            % Set the shutter speed
            C.camera.shutterspeed = shutterspeed{k};

            % Set the filename
            C.session.filenametemplate = imagename;

            % Capture the photo
            C.Capture
        end
        
        % Add a pause.... might not be necessary
        pause(10)   % 10 seconds
                
        % Rotate the camera +/- 90 degrees
        % If j = 1, then we're alread at home and the camera needs to
        % rotate 90 degrees CW
        if j == 1
            % Use pan offsets to rotate +/- 90 degrees
            fprintf(obj1, 'po9000 ');
            fscanf(obj1);
        elseif j == 2
            % Now, rotate back to home, which is an offset of -9000
            fprintf(obj1, 'po-9000 ');
            fscanf(obj1);
        end
        
        % Add a pause.... might not be necessary
        pause(10)   % 10 seconds
             
    end
end


%% Disconnect and Clean Up

% Disconnect from instrument object, obj1.
fclose(obj1);
