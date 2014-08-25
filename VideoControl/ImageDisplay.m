function varargout = ImageDisplay(varargin)
% GUI to display frames arranged in data structures craeted by VideoControl
% Shmuel Ben-Ezra Sep 2005


% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ImageDisplay_OpeningFcn, ...
                   'gui_OutputFcn',  @ImageDisplay_OutputFcn, ...
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

% --- Executes just before ImageDisplay is made visible.
function ImageDisplay_OpeningFcn(hObject, eventdata, handles, varargin)
% Choose default command line output for ImageDisplay
handles.output = hObject;
set(hObject, 'colormap', gray(256));
set(gca, 'xtickmode', 'manual', 'ytickmode', 'manual', 'xtick', [], 'ytick', []);
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ImageDisplay wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = ImageDisplay_OutputFcn(hObject, eventdata, handles)
varargout{1} = handles.output;

% --------------------------------------------------------------------
function FileMenu_Callback(hObject, eventdata, handles)

% --------------------------------------------------------------------
function OpenMenuItem_Callback(hObject, eventdata, handles)
file = uigetfile('*.fig');
if ~isequal(file, 0)
    open(file);
end

% --------------------------------------------------------------------
function PrintMenuItem_Callback(hObject, eventdata, handles)
printdlg(handles.figure1)

% --------------------------------------------------------------------
function CloseMenuItem_Callback(hObject, eventdata, handles)
selection = questdlg(['Close ' get(handles.figure1,'Name') '?'],...
                     ['Close ' get(handles.figure1,'Name') '...'],...
                     'Yes','No','Yes');
if strcmp(selection,'No')
    return;
end

delete(handles.figure1)


% --- Executes on button press in pbLoad.
function pbLoad_Callback(hObject, eventdata, handles)
[handles.filename, pathname] = uigetfile('*.mat', 'Pick a file to open');
if handles.filename == 0, return, end;
fn = [pathname, handles.filename];
structure = load(fn);
field_names = fieldnames(structure);
field_name = field_names{1};
handles.data = getfield(structure, field_name);
if ~iscell(handles.data), return, end;
handles.triggers = length(handles.data);
handles.frames = size(handles.data{1}.frames,4);
handles.trigger = 1;
handles.frame = 1;
% handles.image = imagesc(handles.data{handles.trigger}.frames(:,:,:,handles.frame));
% set(gca, 'xtickmode', 'manual', 'ytickmode', 'manual', 'xtick', [], 'ytick', []);
display_image(handles);
guidata(hObject, handles);
return

% --- Executes on button press in pbShowNext.
function pbShowNext_Callback(hObject, eventdata, handles)
if handles.frame < handles.frames, 
    handles.frame = handles.frame + 1;
elseif handles.trigger < handles.triggers,
    handles.frame = 1;
    handles.trigger = handles.trigger + 1;
else
    return
end;
% handles.image = imagesc(handles.data{handles.trigger}.frames(:,:,:,handles.frame));
% set(gca, 'xtickmode', 'manual', 'ytickmode', 'manual', 'xtick', [], 'ytick', []);
display_image(handles);
guidata(hObject, handles);
return
% --- Executes on button press in pbShowPrev.
function pbShowPrev_Callback(hObject, eventdata, handles)
if handles.frame > 1, 
    handles.frame = handles.frame - 1;
elseif handles.trigger >  1,
    handles.frame = handles.frames;
    handles.trigger = handles.trigger - 1;
else
    return
end;
% handles.image = imagesc(handles.data{handles.trigger}.frames(:,:,:,handles.frame));
% set(gca, 'xtickmode', 'manual', 'ytickmode', 'manual', 'xtick', [], 'ytick', []);
display_image(handles);
guidata(hObject, handles);
return



% --- Executes during object creation, after setting all properties.
function axes1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axes1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate axes1

function display_image(handles)
set(handles.edFileName, 'string', handles.filename);
handles.image = imagesc(handles.data{handles.trigger}.frames(:,:,:,handles.frame));
set(gca, 'xtickmode', 'manual', 'ytickmode', 'manual', 'xtick', [], 'ytick', []);
set(handles.edTrigger, 'string', sprintf('%g / %g', handles.trigger, handles.triggers));
set(handles.edFrame, 'string', sprintf('%g / %g', handles.frame, handles.frames));
return


function edFileName_Callback(hObject, eventdata, handles)


% --- Executes during object creation, after setting all properties.
function edFileName_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edTrigger_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function edTrigger_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edFrame_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function edFrame_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


