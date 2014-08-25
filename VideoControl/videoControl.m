function varargout = videoControl(varargin)
%   VideoControl - launch a GUI to control image acquisition session:
%   The GUI will help you in:
%       craeting the video object, 
%       previewing and snap shotting, 
%       controlling frame grabber parameters, 
%       saving data to a file, creating movies and more...
%   The video object constructor is: videoinput('matrox', 1, 'M_CCIR') -
%   you can find that line of code in function 'pbVideoInput_Callback'
%   below... 
%   If you are working with different video format or another frame brabber vendor, 
%   change the vendor ('matrox') or the video format ('M_CCIR'). 
%   However, changing vendor and/or format may affect the behaviour of the application.
%
%   NOTE:   Begin session by pressing the 'VideoInput' pushbutton to create the video object.
%                  Most controls (push-buttons etc...) will do nothing unless such a video object exists!!!
%   NOTE:   The application sends its messages to the MATLAB environment.
%                  You should keep the MATLAB environment visible. Suggestion: work
%                  with the GUI docked to the MATLAB window (small arrow
%                  on upper-right corner of the window)
%   
%   Quick start:
%       1. Press VideoInput (wait untill the label changes to: 'Delete VideoInput').
%       2. Press Preview (you should see the video stream from the camera, 
%           the label changes to: 'Close Preview').
%       3. Press FramesAcquired (=0), FramesAvailable (=0), IsRunning (No), IsLogging (No) - 
%           all answers appear in the Matlab environment.
%       4. Press START (the acquisition begins with default parameters: FramesPerTrigger=10 etc...).
%       5. Press FramesAcquired (=10), FramesAvailable(=10).
%       6. Press GetData (to get the acquired data from the video object).
%       7. Press Save ( a dialog box appears suggesting a file-name composed from the Test name and 
%           the time yyyymmdd_HHMMSS).
%       8. Press ImageDisplay (it should load another independent GUI to view what you created in VideoControl).
%   
%   Acquisition:
%       Edit the fields: FrameGrabInterval (take a frame every X frames),
%       FramesPerTrigger, TriggerRepeat (the system expects 1+TriggerRepeat triggers after START), 
%       TriggerFrameDelay (number of frames to skip after trigger).
%       Note: When video object is created it always has the defaults values, 
%       regardless of what is written in the edit fields.
%   Source:
%       From this pannel you can control Automatic gain, Brightness, Contrast and 
%       ROI (Region of interest - the portion of the image that will be acquired).
%   Action:
%       START - make the video object running (ready for logging upon
%       trigger)
%       Trigger - useful at manual trigger only, begins logging.
%       STOP - stop the video object from running.
%       GetData - bring acquired data from video object to the MATLAB
%       environment. You can not save data unless you pressed it before!
%       Save - save the acquired data to a file. You can change the
%       suggested file name as you like.
%       ImageDisplay - launch an independent GUI to display images of the
%       unique structure preduced by VIDEOCONTROL.
%   PowerMeter - I am not sure about the validity of this feature. 
%       However it is advised to set the source to AutomaticGain=OFF. 
%       The exposure time of your camera is also important - it should not be auto.
%   Trigger:
%       Immediate - begin logging immediately after you will press START.
%       Manual - begin logging after you will press TRIGGER. 
%       Hardware (4 options) - begin logging upon the selected signal.
%   
%   Logging:
%       LoggingMode - 'memory' (producing data structure that will be saved by SAVE), 
%       'disk&memory' (creating also an avi file) or 'disk'. 
%       Compression - select the compression algorithm for the avi file.
%       Quality [1-100] - select the quality of the compression of the avi file.
%       FramesPerSecond - avi file property.
%       CreateAviFile - Only when you are logging to disk. Do not forget to
%       create avi file before you start logging to a disk. Also, you will
%       not be able to open the avi file unless you closed it 
%       (the push button label changes to CloseAvi. Press it to close the
%       new avi file).
%
%   MENU:
%       On the menu bar you have 'Trigger' and 'Info' to display the status
%       of the video object, video source and trigger info. If your window
%       is docked into the MATLAB window, the menus will join the MATLAB
%       menu bar on top of the window.
%       
%   Data structure:
%       If you had for example 3 triggers with 11 frames per trigger you will create a
%       cell array of length 3. 
%       Let us call the data structure 'd', so all the data from a single trigger 
%       is stored in:
%       d{#trigger}.frames - this is a 4 dimensional array with (rows,
%       columns, bands, frame_index).
%       The GUI ImageDisplay is designed to display
%       that data structure.
%
%       Shmuel Ben-Ezra, Sep 2005, UltraShape, Tel-Aviv, ISRAEL

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @videoControl_OpeningFcn, ...
    'gui_OutputFcn',  @videoControl_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before videoControl is made visible.
function videoControl_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to videoControl (see VARARGIN)
% Choose default command line output for videoControl
handles.output = hObject;
% my global definitions:
handles.data = [];
handles.aviobj =[];
imaqreset
% Update handles structure
guidata(hObject, handles);
% UIWAIT makes videoControl wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% --- Outputs from this function are returned to the command line.
function varargout = videoControl_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --------------------------------------------------------------------
function miFramesPerTrigger_Callback(hObject, eventdata, handles)
if get(handles.pbVideoInput, 'userdata') == 0, return, end;
fpt = num2str(get(handles.vid, 'FramesPerTrigger'));
disp([' Frames per trigger: ', fpt]);
return

% --------------------------------------------------------------------
function miTriggerType_Callback(hObject, eventdata, handles)
if get(handles.pbVideoInput, 'userdata') == 0, return, end;
t = get(handles.vid, 'TriggerType');
disp([' Trigger type: ', t]);
return

% --------------------------------------------------------------------
function miTriggerCondition_Callback(hObject, eventdata, handles)
if get(handles.pbVideoInput, 'userdata') == 0, return, end;
tc = get(handles.vid, 'TriggerCondition');
disp([' Trigger condition: ', tc]);
return

% --------------------------------------------------------------------
function miTriggerSource_Callback(hObject, eventdata, handles)
if get(handles.pbVideoInput, 'userdata') == 0, return, end;
ts = get(handles.vid, 'TriggerSource');
disp([' Trigger source: ', ts]);
return

% --------------------------------------------------------------------
function menuTrigger_Callback(hObject, eventdata, handles)

% --- Executes on button press in pbVideoInput.
function pbVideoInput_Callback(hObject, eventdata, handles)
if get(hObject, 'userdata') == 0, % video is closed
    imaqreset;
    handles.vid = videoinput('matrox', 1, 'M_CCIR');
    handles.source = getselectedsource(handles.vid);
    set(hObject, 'string', 'Delete VideoInput');
    set(hObject, 'userdata', 1);
    guidata(hObject, handles);
    return
else
    delete(handles.vid);
    clear handles.vid;
    set(hObject, 'string', 'VideoInput');
    set(hObject, 'userdata', 0);
    set(handles.pbPreview, 'userdata', 0, 'string', 'Preview');
    %set(handles.pbCreateSource, 'userdata', 0, 'string', 'CreateSource');
    guidata(hObject, handles);
    return
end

% --- Executes on button press in pbPreview.
function pbPreview_Callback(hObject, eventdata, handles)
if get(handles.pbVideoInput, 'userdata') == 0, return, end;
if get(hObject, 'userdata') == 0, %preview is OFF
    preview(handles.vid);
    set(hObject,  'string', 'ClosePreview');
    set(hObject, 'userdata', 1.0);
    guidata(hObject, handles);
    return
else
    closepreview(handles.vid);
    set(hObject, 'string', 'Preview');
    set(hObject, 'userdata', 0.0);
    guidata(hObject, handles);
    return
end

% --- Executes during object creation, after setting all properties.
function figure1_CreateFcn(hObject, eventdata, handles)
handles.vid = [];
handles.source = [];
guidata(hObject, handles);
return

% --- Executes on button press in rbAutomaticGainON.
function rbAutomaticGainON_Callback(hObject, eventdata, handles)
if get(handles.pbVideoInput, 'userdata') == 0, return, end;
if get(hObject, 'value') == 1,
    set(handles.source, 'AutomaticInputGain', 'on');
    set(handles.edGain, 'string', '', 'enable', 'off');
end

% --- Executes on button press in rbAutomaticGainOFF.
function rbAutomaticGainOFF_Callback(hObject, eventdata, handles)
if get(handles.pbVideoInput, 'userdata') == 0, return, end;
if get(hObject, 'value') == 1,
    set(handles.source, 'AutomaticInputGain', 'off');
    set(handles.edGain, 'string', '79', 'enable', 'on');
end

% --- Executes upon editing.
function edGain_Callback(hObject, eventdata, handles)
if get(handles.pbVideoInput, 'userdata') == 0, return, end;
g = str2double(get(hObject, 'string'));
set(handles.source, 'InputGain', g);
return

% --- Executes during object creation, after setting all properties.
function edGain_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

% --- Executes on slider movement.
function slBrightness_Callback(hObject, eventdata, handles)
if get(handles.pbVideoInput, 'userdata') == 0, return, end;
b = round(get(hObject, 'value'));
set(handles.source, 'Brightness', b);
set(handles.edBrightness, 'string', num2str(b));
return

% --- Executes during object creation, after setting all properties.
function slBrightness_CreateFcn(hObject, eventdata, handles)
usewhitebg = 1;
if usewhitebg
    set(hObject,'BackgroundColor',[.9 .9 .9]);
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

% --- Executes upon editing.
function edBrightness_Callback(hObject, eventdata, handles)
if get(handles.pbVideoInput, 'userdata') == 0, return, end;
b = round(str2num(get(hObject, 'string')));
set(handles.slBrightness, 'value', b);
set(handles.source, 'Brightness', b);
return

% --- Executes during object creation, after setting all properties.
function edBrightness_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

% --------------------------------------------------------------------
function miGetSelectedSource_Callback(hObject, eventdata, handles)
if get(handles.pbVideoInput, 'userdata') == 0, return, end;
get(handles.source)
return

% --------------------------------------------------------------------
function menuInfo_Callback(hObject, eventdata, handles)


function edContrast_Callback(hObject, eventdata, handles)
if get(handles.pbVideoInput, 'userdata') == 0, return, end;
c = round(str2num(get(hObject, 'string')));
set(handles.slContrast, 'value', c);
set(handles.source, 'Contrast', c);
return

% --- Executes during object creation, after setting all properties.
function edContrast_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end


% --- Executes on slider movement.
function slContrast_Callback(hObject, eventdata, handles)
% hObject    handle to slContrast (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
if get(handles.pbVideoInput, 'userdata') == 0, return, end;
c = round(get(hObject, 'value'));
set(handles.source, 'Contrast', c);
set(handles.edContrast, 'string', num2str(c));
return

% --- Executes during object creation, after setting all properties.
function slContrast_CreateFcn(hObject, eventdata, handles)
usewhitebg = 1;
if usewhitebg
    set(hObject,'BackgroundColor',[.9 .9 .9]);
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

% --- Executes on button press in pbDefaultsSource.
function pbDefaultsSource_Callback(hObject, eventdata, handles)
if get(handles.pbVideoInput, 'userdata') == 0, return, end;
set(handles.slContrast, 'value', 128);
set(handles.edContrast, 'string', '128');
set(handles.source, 'Contrast', 128);
set(handles.slBrightness, 'value', 128);
set(handles.edBrightness, 'string', '128');
set(handles.source, 'Brightness', 128);
if get(handles.rbAutomaticGainOFF, 'value') == 1,
    set(handles.edGain, 'string', '79');
    set(handles.source, 'InputGain', 79);
end
return

% --- Executes on selection change in ppTriggerConfig.
function ppTriggerConfig_Callback(hObject, eventdata, handles)
% hObject    handle to ppTriggerConfig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: contents = get(hObject,'String') returns ppTriggerConfig contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ppTriggerConfig
if get(handles.pbVideoInput, 'userdata') == 0, return, end;
selection = get(hObject, 'value');
config = triggerinfo(handles.vid);
triggerconfig(handles.vid, config(selection));

% --- Executes during object creation, after setting all properties.
function ppTriggerConfig_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

% --- Executes on button press in pbFramesAcquired.
function pbFramesAcquired_Callback(hObject, eventdata, handles)
if get(handles.pbVideoInput, 'userdata') == 0, return, end;
frames = get(handles.vid, 'FramesAcquired');
s = sprintf('%s%g\n', 'Frames acquired: ', frames);
disp(s);

% --------------------------------------------------------------------
function miGetVideoInput_Callback(hObject, eventdata, handles)
if get(handles.pbVideoInput, 'userdata') == 0, return, end;
get(handles.vid)
return


function edFrameGrabInterval_Callback(hObject, eventdata, handles)
if get(handles.pbVideoInput, 'userdata') == 0, return, end;
set(handles.vid, 'FrameGrabInterval', str2num(get(hObject, 'string')));
guidata(hObject, handles);
return

% --- Executes during object creation, after setting all properties.
function edFrameGrabInterval_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

function edFramesPerTrigger_Callback(hObject, eventdata, handles)
if get(handles.pbVideoInput, 'userdata') == 0, return, end;
set(handles.vid, 'FramesPerTrigger', str2num(get(hObject, 'string')));
guidata(hObject, handles);
return

% --- Executes during object creation, after setting all properties.
function edFramesPerTrigger_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end


function edTriggerRepeat_Callback(hObject, eventdata, handles)
if get(handles.pbVideoInput, 'userdata') == 0, return, end;
set(handles.vid, 'TriggerRepeat', str2num(get(hObject, 'string')));
guidata(hObject, handles);
return

% --- Executes during object creation, after setting all properties.
function edTriggerRepeat_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

% --- Executes on button press in pbDefaultsAcquisition.
function pbDefaultsAcquisition_Callback(hObject, eventdata, handles)
if get(handles.pbVideoInput, 'userdata') == 0, return, end;
set(handles.edFrameGrabInterval, 'string', '1');
set(handles.vid, 'FrameGrabInterval', 1);
set(handles.edFramesPerTrigger, 'string', '10');
set(handles.vid, 'FramesPerTrigger', 10);
set(handles.edTriggerRepeat, 'string', '0');
set(handles.vid, 'TriggerRepeat', 0);
set(handles.edTriggerFrameDelay, 'string', '0');
set(handles.vid, 'TriggerFrameDelay', 0);
guidata(hObject, handles);
return

function edTriggerFrameDelay_Callback(hObject, eventdata, handles)
if get(handles.pbVideoInput, 'userdata') == 0, return, end;
set(handles.vid, 'TriggerFrameDelay', str2num(get(hObject, 'string')));
guidata(hObject, handles);
return

% --- Executes during object creation, after setting all properties.
function edTriggerFrameDelay_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end




% --- Executes on button press in pbGetSnapshot.
function pbGetSnapshot_Callback(hObject, eventdata, handles)
if get(handles.pbVideoInput, 'userdata') == 0, return, end; % video object absent
if get(hObject, 'userdata') == 0,
    set(hObject, 'userdata', 1.0);
    s = getsnapshot(handles.vid);
    figure(1);
    imshow(s);
    set(hObject, 'userdata', 0.0);
    guidata(hObject, handles);
    return
else
    return
end
return

% --- Executes on button press in pbFramesAvailable.
function pbFramesAvailable_Callback(hObject, eventdata, handles)
if get(handles.pbVideoInput, 'userdata') == 0, return, end;
frames = get(handles.vid, 'FramesAvailable');
s = sprintf('%s%g\n', 'Frames available: ', frames);
disp(s);
return

% --- Executes on button press in pbStart.
function pbStart_Callback(hObject, eventdata, handles)
if get(handles.pbVideoInput, 'userdata') == 0, return, end;
if isrunning(handles.vid), return, end;
start(handles.vid);
% sState = get(hObject, 'string');
% if ~isrunning(handles.vid) & ~strcmp(sState, 'START'), % strange case 1
%     set(hObject, 'string', 'START');
%     return;
% end
% if isrunning(handles.vid) & strcmp(sState, 'START'), % strange case 2
%     set(hObject, 'string', 'STOP');
%     return;
% end
% if strcmp(sState, 'STOP'),
%     stop(handles.vid);
%     set(hObject, 'string', 'START');
% elseif strcmp(sState, 'START'),
%     start(handles.vid);
%     set(hObject, 'string', 'STOP');
% end
% guidata(hObject, handles);

% v = get(handles.ppTriggerConfig, 'value');
% if v == 1 , %trigger immediate
%     if strcmp(sStart, 'START'),
%         if isrunning(handles.vid), return, end;
%         start(handles.vid);
%         set(hObject, 'string', 'STOP');
%         guidata(hObject, handles);
%     elseif strcmp(sStart, 'STOP'),
%         stop(handles.vid);
%         set(hObject, 'string', 'START');
%         guidata(hObject, handles);
%     end
% elseif v == 2, % trigger manual
%     if strcmp(sStart, 'START'),
%         if ~isrunning(handles.vid),
%             start(handles.vid);
%         end;
%         set(hObject, 'string', 'Trigger'); % TODO:: condition if isrunning
%         guidata(hObject, handles);
%     elseif strcmp(sStart, 'Trigger'), % TODO::: continue triggers untill triggerrepeat+1 == triggersexecuted
%         if isrunning(handles.vid) & ~islogging(handles.vid),
%             trigger(handles.vid);
%         end
%         if get(handles.vid, 'TriggersExecuted') == get(handles.vid, 'TriggerRepeat') + 1,
%             set(hObject, 'string', 'START');
%         end
%         guidata(hObject, handles);
%     end
% end
return

% --- Executes on button press in pbTrigger.
function pbTrigger_Callback(hObject, eventdata, handles)
if get(handles.pbVideoInput, 'userdata') == 0, return, end;
if ~strcmp(get(handles.vid, 'TriggerType'), 'manual'), return, end;
if ~isrunning(handles.vid), return, end;
if islogging(handles.vid), return, end;
trigger(handles.vid);
return

% --- Executes on button press in pbStop.
function pbStop_Callback(hObject, eventdata, handles)
if get(handles.pbVideoInput, 'userdata') == 0, return, end;
if ~isrunning(handles.vid), return, end;
stop(handles.vid);
return

% % --- Executes on button press in pbImaqMontage.
% function pbImaqMontage_Callback(hObject, eventdata, handles)
% if get(handles.pbVideoInput, 'userdata') == 0, return, end;
% % figure(2);% TO DO:: use the correct data structure to display...
% % imaqmontage(handles.data);
% return

% --- Executes on button press in pbFlushData.
function pbFlushData_Callback(hObject, eventdata, handles)
if get(handles.pbVideoInput, 'userdata') == 0, return, end;
flushdata(handles.vid);
return

% % --- Executes on button press in pbImWrite.
% function pbImWrite_Callback(hObject, eventdata, handles)
% %imageDisplay;
% imageDisplay('Load', gcbo, [], guidata(gcbo), handles.data);
% return

% --- Executes on button press in pbImageDisplay.
function pbImageDisplay_Callback(hObject, eventdata, handles)
ImageDisplay
return

% --- Executes on button press in pbGetData.
function pbGetData_Callback(hObject, eventdata, handles)
if get(handles.pbVideoInput, 'userdata') == 0, return, end;
if get(handles.vid, 'FramesAvailable') == 0, return, end;
if get(handles.vid, 'TriggersExecuted') < 1, return, end;
handles.data = [];
T = get(handles.vid, 'TriggersExecuted');
for t=1:T,
    [handles.data{t}.frames, handles.data{t}.time, handles.data{t}.metadata] = getdata(handles.vid);
end
guidata(hObject, handles);
return

% --- Executes on button press in pbSave.
function pbSave_Callback(hObject, eventdata, handles)
if get(handles.pbVideoInput, 'userdata') == 0, return, end;
if isempty(handles.data), return, end;
tx = get(handles.edTransducerID, 'string');
d=handles.data;
c = fix(clock);
filename=sprintf('%s_%4d-%02d-%02d_%02d%02d%02d%s', tx, c(1), c(2), c(3), c(4), c(5), c(6), '.mat');
prompt={'Enter file name:'};
name='Save current data to a file';
numlines=1;
defaultanswer= {filename};
filename2='';
filename2=inputdlg(prompt,name,numlines,defaultanswer);
if isempty(filename2), return, end;
save(filename2{1}, 'd');
return

% --- Executes on button press in pbPowerMeter.
function pbPowerMeter_Callback(hObject, eventdata, handles)
if get(handles.pbVideoInput, 'userdata') == 0, return, end;
if strcmp(get(hObject, 'string'), 'Stop PM'),
    stop(handles.vid);
    set(hObject, 'string', 'PowerMeter'); % send a message into the interruptibble loop via the string?
    return;
end
if islogging(handles.vid), disp('Video object is logging - can not run power meter!'), return, end;
if isrunning(handles.vid), disp('Video object is running - can not run power meter!'), return, end;
set(handles.edPowerMeter, 'string', '');
start(handles.vid);
set(hObject, 'string', 'Stop PM');
while strcmp(get(hObject, 'string'), 'Stop PM'),
    d = getsnapshot(handles.vid); % get 1 frame
    %%     r = get(handles.vid, 'ROI');
    %%     max = ( r(3) - r(1) )*(r(4) - r(2) )*255;
    max = 255*size(d, 1)*size(d, 2);
    power = sum(sum(d))/max;
    set(handles.edPowerMeter, 'string', num2str(power, 3));
    guidata(hObject, handles);
    pause(0.2);
end
%set(hObject, 'string', 'PowerMeter');
return

% --- Executes on editing.
function edPowerMeter_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function edPowerMeter_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

% --- Executes on editing.
function edROIx_Callback(hObject, eventdata, handles)
% if get(handles.pbVideoInput, 'userdata') == 0, return, end;
% a = get(handles.vid, 'ROI');
% new = str2num(get(hObject, 'string'));
% set(handles.vid, 'ROI', [new a(2) a(3) a(4)]);
return;

% --- Executes during object creation, after setting all properties.
function edROIx_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

% --- Executes on editing.
function edROIy_Callback(hObject, eventdata, handles)
% if get(handles.pbVideoInput, 'userdata') == 0, return, end;
% a = get(handles.vid, 'ROI');
% new = str2num(get(hObject, 'string'));
% set(handles.vid, 'ROI', [a(1) new a(3) a(4)]);
return;

% --- Executes during object creation, after setting all properties.
function edROIy_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

% --- Executes on editing.
function edROIwidth_Callback(hObject, eventdata, handles)
% if get(handles.pbVideoInput, 'userdata') == 0, return, end;
% a = get(handles.vid, 'ROI');
% new = str2num(get(hObject, 'string'));
% set(handles.vid, 'ROI', [a(1) a(2) new a(4)]);
return;

% --- Executes during object creation, after setting all properties.
function edROIwidth_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

% --- Executes on editing.
function edROIheight_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function edROIheight_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

% --- Executes on button press in pbROIdefaults.
function pbROIdefaults_Callback(hObject, eventdata, handles)
if get(handles.pbVideoInput, 'userdata') == 0, return, end;
a = get(handles.vid, 'videoresolution');
x = 0; y = 0;
set(handles.vid, 'ROI', [x y a(1) a(2)]);
set(handles.edROIx, 'string', num2str(x));
set(handles.edROIy, 'string', num2str(y));
set(handles.edROIwidth, 'string', num2str(a(1)));
set(handles.edROIheight, 'string', num2str(a(2)));
guidata(hObject, handles);
return

% --- Executes on button press in pbROIupdate.
function pbROIupdate_Callback(hObject, eventdata, handles)
if get(handles.pbVideoInput, 'userdata') == 0, return, end;
a = zeros(1,4);
a(1) = str2num(get(handles.edROIx, 'string'));
a(2) = str2num(get(handles.edROIy, 'string'));
a(3) = str2num(get(handles.edROIwidth, 'string'));
a(4) = str2num(get(handles.edROIheight, 'string'));
set(handles.vid, 'ROI', a);
guidata(hObject, handles);
return

% --- Executes on editing.
function edTransducerID_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function edTransducerID_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

% --- Executes on button press in pbIsRunning.
function pbIsRunning_Callback(hObject, eventdata, handles)
if get(handles.pbVideoInput, 'userdata') == 0, return, end;
s = isrunning(handles.vid);
switch s
    case 0
        disp(' Video object is NOT running');
    case 1
        disp(' Video object is running');
end
return

% --- Executes on button press in pbIsLogging.
function pbIsLogging_Callback(hObject, eventdata, handles)
if get(handles.pbVideoInput, 'userdata') == 0, return, end;
s = islogging(handles.vid);
switch s
    case 0
        disp(' Video object is NOT logging');
    case 1
        disp(' Video object is logging');
end
return

% --- Executes on selection change in ppLoggingMode.
function ppLoggingMode_Callback(hObject, eventdata, handles)
if get(handles.pbVideoInput, 'userdata') == 0, return, end;
index = get(hObject, 'value');
str = get(hObject, 'string');
sLoggingMode = str{index};
set(handles.vid, 'LoggingMode', sLoggingMode);
guidata(hObject, handles);
return

% --- Executes on creation.
function ppLoggingMode_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

% --- Executes on selection change in ppCompression.
function ppCompression_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function ppCompression_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

% --- Executes upon editing.
function edQuality_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function edQuality_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

% --- Executes on button press in tbAvi.
function tbAvi_Callback(hObject, eventdata, handles)
if get(handles.pbVideoInput, 'userdata') == 0,
    set(hObject, 'string', 'CreateAvi'); % label 'Create avifile'
    set(hObject, 'userdata', 1);
    return;
end;
logging_mode_index = get(handles.ppLoggingMode, 'value');
if logging_mode_index == 1, return, end; % logging mode = memory
state = get(hObject, 'userdata');
if state == 1, % create avi
    %try
    tx = get(handles.edTransducerID, 'string');
    c = fix(clock);
    filename=sprintf('%s_%4d-%02d-%02d_%02d%02d%02d%s', tx, c(1), c(2), c(3), c(4), c(5), c(6), '.avi');
    prompt={'Enter avi file name:'};
    name='Create avi file for disk logging';
    numlines=1;
    defaultanswer= {filename};
    filename = '';
    filename=inputdlg(prompt,name,numlines,defaultanswer);
    if isempty(filename), return, end;
    sCompression_index = get(handles.ppCompression, 'value');
    sCompressionCell = get(handles.ppCompression, 'string');
    sCompression = sCompressionCell{sCompression_index};
    fps = str2num(get(handles.edFps, 'string'));
    quality = str2num(get(handles.edQuality, 'string'));
    handles.aviobj = avifile(filename{1}, 'Colormap', gray(256), 'Compression', sCompression, 'Quality', quality, 'FPS', fps);
    set(handles.vid, 'DiskLogger', handles.aviobj);
    set(hObject, 'string', 'CloseAvi'); % label 'Close avifile'
    set(handles.tbAvi, 'userdata', 0);
    guidata(hObject, handles);
    %catch
    %     set(hObject, 'string', str{1}); % label 'Create avifile'
    %     value = get(hObject, 'max');
    %     set(hObject, 'value', value);
    %end
elseif state == 0, % close avi
    if isrunning(handles.vid),
        disp('Can not close avi file while video object is running!!!');
        return;
    end
    if get(handles.vid, 'FramesAcquired') > get(handles.vid, 'DiskLoggerFrameCount')
        disp('Logging... please wait!');
        return;
    end
    if ~isempty(handles.aviobj),
        handles.aviobj = close(handles.vid.DiskLogger);
    end
    set(hObject, 'string', 'CreateAvi'); % label 'Create avifile'
    set(handles.tbAvi, 'userdata', 1);
    guidata(hObject, handles);
end
return

% --- Executes on editing.
function edFps_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function edFps_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end


