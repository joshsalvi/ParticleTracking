function [] = DLTdv3(varargin)

% function [] = DLTdv3()
%
% DLTdv is a digitizing environment designed to acquire
% 3D coordinates from 2-4 video sources calibrated via a set of
% DLT coefficients.  It can also digitize one or more video streams
% without DLT coefficients.
%
% Features:
%		*Simultaneous viewing of up to 4 video files
%		*Displays line of least residual given a point on one of the
%			images in 3D mode
%   *Automatic tracking of markers or features from frame to frame
%   *Kalman and Double Exponential predictors to enhance auto-tracking
%   *Display and track color or grayscale videos
%		*Change frame sync of the different video streams
%   *Change the gamma of the videos
%		*Load and modify previously digitized trials
%
%	See the associated RTF or PDF document for complete usage information,
%	see the online video tutorials for a basic introduction.
%
% Version 1 - Tyson Hedrick 8/1/04
% Version 2 - Tyson Hedrick 8/4/05
% Version 3 - Tyson Hedrick 3/1/08

%% Function initialization
if nargin==0 % no inputs, just fix the path and run the gui

  % check Matlab version and don't start if not >= 7.  Many of the figure
  % and gui controls changed in the 6.5 --> 7.0 jump and it is no longer
  % possible to support the older versions.
  v=version;
  if str2double(v(1:3))<7
    beep
    disp('DLTdv3 requires MATLAB version 7 or later')
    return
  end
  
  % check to make sure we were called with the appropriate name
  if strcmpi(mfilename,'dltdv3')==0
    beep
    disp('Error: This program must be named "DLTdv3.m" to function properly.')
    return
  end

  % check to see if we are in the path, add us if we are not
  dltloc=which('DLTdv3');
  if ispc, p1=lower(path); else p1=path; end % current path
  % DLTdv3 directory
  dlttrim=dltloc(1:end-9);
  if ispc, dlttrim=lower(dlttrim); end
  % create an index of path separators, including the start and end if
  % necessary
  idx=find(p1==pathsep);
  if idx(end)~=numel(p1)
    idx(end+1)=numel(p1)+1;
  end
  idx2(1)=0;
  idx2(2:numel(idx)+1)=idx;

  % loop through the path and see if dltloc matches it
  for i=1:numel(idx2)-1
    pstring=p1(idx2(i)+1:idx2(i+1)-1); % path segment
    if strcmp(pstring,dlttrim)
      inPath=1; % found a match
      break
    else
      inPath=0;
    end
  end
  if inPath==0 % didn't find a match
    % add DLTdv3's directory to the end of the path
    addpath(dlttrim,p1);
    disp(sprintf('Adding %s to the MATLAB search path',dlttrim))
  end
  call=99; % go creat the GUI if we didn't get any input arguments

elseif nargin==1 % assume a switchyard call but no data
  call=varargin{1};
  ud=get(gcbo,'Userdata'); % get simple userdata
  h=ud.handles; % get the handles
  uda=get(h(1),'Userdata'); % get complete userdata
  h=uda.handles; % get complete handles
  sp=get(h(32),'Value'); % get the selected point

elseif nargin==2 % assume a switchyard call and data
  call=varargin{1};
  uda=varargin{2};
  h=uda.handles; % get complete handles
  sp=get(h(32),'Value'); % get the selected point

elseif nargin==3 % switchyard call, data & subfunction specific data
  call=varargin{1};
  uda=varargin{2};
  h=uda.handles; % get complete handles
  sp=get(h(32),'Value'); % get the selected point
  oData=varargin{3}; % store the misc. other variable in oData
else
  disp('DLTdv3: incorrect number of input arguments')
  return
end

% switchyard to handle updating & processing tasks for the figure
switch call

%% case 99 - GUI figure creation
  case {99} % Initialize the GUI

    disp(sprintf('\n'))
    disp('DLTdv3 (updated January 18, 2009)')
    disp(sprintf('\n'))
    disp('Visit http://www.unc.edu/~thedrick/ for more information,')
    disp('tutorials, sample data & updates to this program.')
    disp(sprintf('\n'))

    % layout parameters for controls window
    top=40.23;
    width=58;

    h(1) = figure('Units','characters',... % control figure
      'Color',[0.831 0.815 0.784]','Doublebuffer','on', ...
      'IntegerHandle','off','MenuBar','none',...
      'Name','DLTdv3 controls','NumberTitle','off',...
      'Position',[10 10 width top],'Resize','off',...
      'HandleVisibility','callback','Tag','figure1',...
      'UserData',[],'Visible','on','deletefcn','DLTdv3(13)',...
      'interruptible','on');

    h(29) = uicontrol('Parent',h(1),'Units','characters',... % Video frame
      'Position',[3 24.2 51.5 10.0],'Style','frame','BackgroundColor',...
      [0.568 0.784 1],'string','Points and auto-tracking');

    h(30) = uicontrol('Parent',h(1),... % Points frame part 1
      'Units','characters','Position',[3 top-28.73 51.5 12.3],'Style',...
      'frame','BackgroundColor',[0.788 1 0.576],'string',...
      'Points and auto-tracking');

    uicontrol('Parent',h(1),'Units','characters',... % Points frame part 2
      'Position',[3 top-39.23 31.5 10.5],'Style','frame',...
      'BackgroundColor',[0.788 1 0.576],'string',...
      'Points and auto-tracking');

    uicontrol('Parent',h(1),... % blank string
      'Units','characters','Position',[3.1 top-29.68 31.3 4.6],'Style',...
      'text','BackgroundColor',[0.788 1 0.576],'string','');

    uicontrol('Parent',h(1),'Units','characters',... % Points frame part 3
      'Position',[23 top-39.23 31.5 2.8],'Style','frame',...
      'BackgroundColor',[0.788 1 0.576],'string','bottom right');

    uicontrol('Parent',h(1),... % blank string
      'Units','characters','Position',[3.1 top-39.15 31.3 4.6],'Style',...
      'text','BackgroundColor',[0.788 1 0.576],'string','');

    h(5) = uicontrol('Parent',h(1),'Units','characters',... % frame slider
      'Position',[7.2 top-15.23 44.2 1.2],'String',{  'frame' },...
      'Style','slider','Tag','slider2','Callback',...
      'DLTdv3(1)','Enable','off');

    h(6) = uicontrol('Parent',h(1),... % initialize button
      'Units','characters','Position',[2.2 top-4.43 14 3],'String',...
      'Initialize','Callback','DLTdv3(0)','ToolTipString', ...
      'Load the videos and DLT specification','Tag','pushbutton1');

    h(7) = uicontrol('Parent',h(1),... % Save data button
      'Units','characters','Position',[21 top-2.73 14.4 1.8],'String',...
      'Save Data','Tag','pushbutton3',...
      'Callback','DLTdv3(5)','Enable','off');

    % h(8) - frame number text box (see below)

    % h(10) - unused

    % h(11) - unused

    % h(12) - color control check box, see below

    h(18) = uicontrol('Parent',h(1),... % gamma control label
      'Units','characters','BackgroundColor',[0.568 0.784 1],...
      'HorizontalAlignment','left','Position',[7 top-8.03 20.4 1.3],...
      'String','Video gamma','Style','text','Tag','text1');

    uicontrol('Parent',h(1),... % color video control label
      'Units','characters','BackgroundColor',[0.568 0.784 1],...
      'HorizontalAlignment','left','Position',[37 top-8.03 15.0 1.3],...
      'String','Display in color','Style','text','Tag','text1');

    h(12)=uicontrol('Parent',h(1),... % Color display checkbox
      'Units','characters','BackgroundColor',[0.568 0.784 1],...
      'Position',[43 top-9.23 4 1],'Value',0,'Style','checkbox','Tag',...
      'colorVideos','enable','off','Callback','DLTdv3(15)');

    h(13) = uicontrol('Parent',h(1),... % video gamma slider
      'Units','characters','Position',[7 top-9.23 28 1.3],'String',...
      {  'gamma' },'Style','slider','Tag','slider1','Min',.1','Max',...
      2,'Value',1,'Callback','DLTdv3(1)', ...
      'Enable','off', 'ToolTipString','Video Gamma slider');

    h(14) = uicontrol('Parent',h(1),'Units','characters',... % quit button
      'Position',[39.8 top-4.43 15.2 3],'String','Quit',...
      'Tag','pushbutton4','Callback','DLTdv3(11)','enable','on');

    h(15) = uicontrol('Parent',h(1),... % camera 2 offset
      'Units','characters','BackgroundColor',[1 1 1],'Position',...
      [24.2 top-11.68 5 1.5],'String','0','Style','edit','Tag','edit1', ...
      'Callback','DLTdv3(8)','Enable','off');

    uicontrol('Parent',h(1),... % camera 2 offset label
      'Units','characters','BackgroundColor',[0.568 0.784 1],...
      'HorizontalAlignment','right','Position',[20.6 top-11.83 3.2 1.3],...
      'String','2','Style','text','Tag','text3');

    h(16) = uicontrol('Parent',h(1),... % camera 3 offset
      'Units','characters','BackgroundColor',[1 1 1],'Position',...
      [34.4 top-11.68 5 1.5],'String','0','Style','edit','Tag','edit2', ...
      'Callback','DLTdv3(8)','enable','off');

    uicontrol('Parent',h(1),... % camera 3 offset label
      'Units','characters','BackgroundColor',[0.568 0.784 1],...
      'HorizontalAlignment','right',...
      'Position',[30.6 top-11.83 3.2 1.3],'String','3','Style','text',...
      'Tag','text4');

    h(17) = uicontrol('Parent',h(1),... % camera 4 offset
      'Units','characters','BackgroundColor',[1 1 1],'Position',...
      [44.8 top-11.68 5 1.5],'String','0',...
      'Style','edit','Tag','edit3','Callback','DLTdv3(8)', ...
      'enable','off');

    uicontrol('Parent',h(1),... % camera 4 offset label
      'Units','characters','BackgroundColor',[0.568 0.784 1],...
      'HorizontalAlignment','right','Position',[41.2 top-11.83 3.2 1.3],...
      'String','4','Style','text','Tag','text5');

    % h(18) - Gamma control label, see above

    % h(19) - see below (add point button)

    h(20) = uicontrol('Parent',h(1),... % frame offsets label
      'Units','characters','BackgroundColor',[0.568 0.784 1],...
      'HorizontalAlignment','left','Position',[7 top-11.73 14.2 1.3],...
      'String','Frame offsets','Style','text','Tag','text2');

    uicontrol('Parent',h(1),... % frame slider label
      'Units','characters','BackgroundColor',[0.568 0.784 1],...
      'HorizontalAlignment','left','Position',[7 top-13.73 26.6 1.1],...
      'String','Frame number:','Style','text','Tag','text6');

    h(21) = uicontrol('Parent',h(1),... % frame slider label
      'Units','characters','BackgroundColor',[0.568 0.784 1],...
      'HorizontalAlignment','left','Position',[35 top-13.73 6.6 1.1],...
      'String','/NaN','Style','text','Tag','text6');

    h(8) = uicontrol('Parent',h(1),... % frame text box
      'Units','characters','BackgroundColor',[1 1 1],'Position',...
      [24 top-13.73 10 1.5],'String','0','Style','edit','Tag','edit3',...
      'Callback','DLTdv3(7)','enable','off');

    h(22) = uicontrol('Parent',h(1),... % load previous data button
      'Units','characters','Position',[21 top-5.23 14.4 1.7],'String',...
      'Load Data','Tag','pushbutton5','enable','off','Callback',...
      'DLTdv3(6)');

    h(23) = uicontrol('Parent',h(1),... % Autotrack search width label
      'Units','characters','BackgroundColor',[0.788 1 0.576],...
      'HorizontalAlignment','left','Position',[7 top-26.03 26.6 1.3],...
      'String','Autotrack search area size','Style','text',...
      'Tag','text15');

    h(25) = uicontrol('Parent',h(1),... % Autotrack threshold label
      'Units','characters','BackgroundColor',[0.788 1 0.576],...
      'HorizontalAlignment','left','Position',[7 top-27.73 26.6 1.3],...
      'String','Autotrack threshold','Style','text',...
      'Tag','text16');

    h(27) = uicontrol('Parent',h(1),... % Autotrack fit
      'Units','characters','BackgroundColor',[0.788 1 0.576],...
      'HorizontalAlignment','left','Position',[7 top-29.23 26.6 1.3],...
      'String','Autotrack fit: --','Style','text','Tag','text17');

    h(31) = uicontrol('Parent',h(1),... % Current point label
      'Units','characters','BackgroundColor',[0.788 1 0.576],...
      'HorizontalAlignment','left','Position',[7 top-19.23 14.2 1.3],...
      'String','Current point','Style','text','Tag','text13');

    h(32) = uicontrol(... % Current point pull-down menu
      'Parent',h(1),'Units','characters','Position',...
      [21.6 top-19.33 10 1.6],'String',' 1','Style','popupmenu',...
      'Value',1,'Tag','popupmenu1','Enable','off','Callback',...
      'DLTdv3(1)');

    h(19) = uicontrol('Parent',h(1),... % add-a-point button
      'Units','characters','Position',[33.2 top-19.33 16 1.6],'String',...
      'Add a point','Callback','DLTdv3(12)','ToolTipString', ...
      'Add a point to the pull down menu','Tag','pushbutton1', ...
      'enable','off');

    h(33) = uicontrol('Parent',h(1),... % DLT residual
      'Units','characters','BackgroundColor',[0.788 1 0.576],...
      'HorizontalAlignment','left','Position',[7 top-30.7 26.6 1.3],...
      'String','DLT residual: --','Style','text','Tag','text18');

    h(34) = uicontrol('Parent',h(1), ... % Autotrack mode label
      'Units','characters','Position',[7 top-21.63 24.2 1.3],...
      'BackgroundColor',[0.788 1 0.576],'HorizontalAlignment','left',...
      'Style','text','String','Autotrack mode');

    h(35) = uicontrol(... % Current point pull-down menu
      'Parent',h(1),'Units','characters','Position',...
      [24 top-21.48 20 1.6],'String',...
      'off|auto-advance|semiautomatic|automatic|multi',...
      'Style','popupmenu',...
      'Value',1,'Tag','popupmenu1','Enable','off','Callback',...
      'DLTdv3(1)');

    %h(36) & h(37) are unused

    h(38) = uicontrol('Parent',h(1),... % Autotrack search area size
      'Units','characters','BackgroundColor',[1 1 1],'Position',...
      [36.8 top-26.13 9.8 1.6],'String','9','Style','edit','Tag',...
      'edit7','Callback','DLTdv3(9)','enable','off');

    h(39) = uicontrol('Parent',h(1),... % Autotrack threshold
      'Units','characters','BackgroundColor',[1 1 1],'Position', ...
      [36.8 top-27.93 9.8 1.6],'String','9','Style','edit','Tag', ...
      'edit8','Callback','DLTdv3(10)','enable','off');

    % h(40) - h(43) movie axes in video figure

    % h(50) - unused

    h(51)=axes('Position',... % create autotrack image axis
      [.63 .10 .30 .165],'XTickLabel','', ...
      'YTickLabel','','Visible','on','Parent',h(1),'box','off');
    c=(repmat((0:1/254:1)',1,3)); % grayscale color map
    image('Parent',h(51),'Cdata',chex(1,21,21).*255, ...
      'CDataMapping','direct'); % display the target image
    colormap(h(51),c)
    xlim(h(51),[1 21]);
    ylim(h(51),[1 21]);

    h(52)=uicontrol('Parent',h(1), ... % DLT visual feedback label
      'Units','characters','Position',[7 top-36.63 24.2 1.3],...
      'BackgroundColor',[0.788 1 0.576],'HorizontalAlignment','left',...
      'Style','text','String','DLT visual feedback');

    h(53)=uicontrol('Parent',h(1),... % DLT visual feedback checkbox
      'Units','characters','BackgroundColor',[0.788 1 0.576],...
      'Position',[29 top-36.33 4 1],'Value',1,'Style','checkbox','Tag',...
      'DLTfeedbackbox','enable','off','Callback','DLTdv3(1)');

    h(54)=uicontrol('Parent',h(1), ... % Centroid finding label
      'Units','characters','Position',[7 top-38.53 24.2 1.3],...
      'BackgroundColor',[0.788 1 0.576],'HorizontalAlignment','left',...
      'Style','text','String','Find marker centroid');

    h(55)=uicontrol('Parent',h(1),... % Centroid finding checkbox
      'Units','characters','BackgroundColor',[0.788 1 0.576],...
      'Position',[29 top-38.2 4 1],'Value',0,'Style','checkbox','Tag',...
      'findCentroidBox','enable','off','Callback','DLTdv3(14)');

    h(56) = uicontrol('Parent',h(1), ... % Autotrack predictor mode label
      'Units','characters','Position',[7 top-23.63 29.2 1.3],...
      'BackgroundColor',[0.788 1 0.576],'HorizontalAlignment','left',...
      'Style','text','String','Autotrack predictor');

    predMenu={'extended Kalman','double exponential','1st order poly',...
      'static point'};

    h(57) = uicontrol(... % Autotrack predictor mode menu
      'Parent',h(1),'Units','characters','Position',...
      [30.2 top-23.63 20 1.6],'String',predMenu,'Style','popupmenu',...
      'Value',1,'Tag','popupmenu2','Enable','off','Callback',...
      'DLTdv3(1)');

    h(58) = uicontrol('Parent',h(1), ... % Centroid color label
      'Units','characters','Position',[34 top-38.53 14.2 1.3],...
      'BackgroundColor',[0.788 1 0.576],'HorizontalAlignment','left',...
      'Style','text','String','Color');

    h(59) = uicontrol(... % Centroid color menu
      'Parent',h(1),'Units','characters','Position',...
      [42 top-38.43 11 1.6],'String',{'black','white'},'Style',...
      'popupmenu','Value',1,'Tag','popupmenu3','Enable','off');

    h(60) = uicontrol('Parent',h(1), ... % DLT threshold label
      'Units','characters','Position',[9 top-32.83 19.2 1.3],...
      'BackgroundColor',[0.788 1 0.576],'HorizontalAlignment','left',...
      'Style','text','String','Threshold:');

    h(61) = uicontrol('Parent',h(1),... % DLT residual threshold
      'Units','characters','BackgroundColor',[1 1 1],'Position', ...
      [21.8 top-32.8 9.8 1.6],'String','3','Style','edit','Tag','edit8',...
      'Callback','DLTdv3(10)','enable','off');

    h(62) = uicontrol('Parent',h(1), ... % Update all videos
      'Units','characters','Position',[7 top-34.73 19.2 1.3],...
      'BackgroundColor',[0.788 1 0.576],'HorizontalAlignment','left',...
      'Style','text','String','Update all videos');

    h(63)=uicontrol('Parent',h(1),... % Update all videos checkbox
      'Units','characters','BackgroundColor',[0.788 1 0.576],...
      'Position',[29 top-34.6 4 1],'Value',1,'Style','checkbox','Tag',...
      'updateVideos','enable','off');

    ud.handles=h; % simple userdata object

    % for each handle set all handle info in userdata
    for i=1:numel(h)
      set(h(i),'Userdata',ud);
    end

    return

%% case 0 - Initialize button callback
  case {0} % Initialize button press from the GUI

    % ask the user how many videos to load
    [uda.nvid,ok]=...
      listdlg('PromptString','How many videos do you have?', ...
      'SelectionMode','single','ListString',{'1','2','3','4'}, 'Name', ...
      '# of videos','listsize',[160 80]);
    pause(0.1); % make sure that the listdlg executed (MATLAB bug)

    if ok==0
      disp('Initialization cancelled, please try again.')
      return
    end

    % Create a new figure for movie display
    h(2) = figure('Units','characters',... % movie figure
      'Color',[0.831 0.815 0.784]','Doublebuffer','on', ...
      'KeyPressFcn','DLTdv3(2)', ...
      'IntegerHandle','off','MenuBar','none',...
      'Name','DLTdv3 videos','NumberTitle','off',...
      'HandleVisibility','callback','Tag','figure1',...
      'UserData',uda,'Visible','on','Units','Pixels', ...
      'deletefcn','DLTdv3(13)','pointer','cross', ...
      'Tag','VideoFigure','interruptible','on');

    if uda.nvid==2 % two videos
      h(40)=axes('Position',[.01 .01 .49 .99],'XTickLabel','', ...
        'YTickLabel','','ButtonDownFcn','DLTdv3(3)', ...
        'Visible','off'); % create movie1 axis
      h(41)=axes('Position',[.51 .01 .49 .99],'XTickLabel','', ...
        'YTickLabel','','ButtonDownFcn','DLTdv3(3)', ...
        'Visible','off'); % create movie2 axis
    elseif uda.nvid==3 % three videos
      h(40)=axes('Position',[.01 .51 .49 .49],'XTickLabel','', ...
        'YTickLabel','','ButtonDownFcn','DLTdv3(3)', ...
        'Visible','off'); % create movie1 axis
      h(41)=axes('Position',[.51 .51 .49 .49],'XTickLabel','', ...
        'YTickLabel','','ButtonDownFcn','DLTdv3(3)', ...
        'Visible','off'); % create movie2 axis
      h(42)=axes('Position',[.01 .01 .49 .49],'XTickLabel','', ...
        'YTickLabel','','ButtonDownFcn','DLTdv3(3)', ...
        'Visible','off'); % create movie3 axis
    elseif uda.nvid==4 % four videos
      h(40)=axes('Position',[.01 .51 .49 .49],'XTickLabel','', ...
        'YTickLabel','','ButtonDownFcn','DLTdv3(3)', ...
        'Visible','off'); % create movie1 axis
      h(41)=axes('Position',[.51 .51 .49 .49],'XTickLabel','', ...
        'YTickLabel','','ButtonDownFcn','DLTdv3(3)', ...
        'Visible','off'); % create movie2 axis
      h(42)=axes('Position',[.01 .01 .49 .49],'XTickLabel','', ...
        'YTickLabel','','ButtonDownFcn','DLTdv3(3)', ...
        'Visible','off'); % create movie3 axis
      h(43)=axes('Position',[.51 .01 .49 .49],'XTickLabel','', ...
        'YTickLabel','','ButtonDownFcn','DLTdv3(3)', ...
        'Visible','off'); % create movie4 axis
    elseif uda.nvid==1 % one video
      h(40)=axes('Position',[.01 .01 .99 .99],'XTickLabel','', ...
        'YTickLabel','','ButtonDownFcn','DLTdv3(3)', ...
        'Visible','off'); % create movie1 axis
    else
      disp('Bad input, try to initialize again')
      close(h(2)); % close movie window
      return
    end

    for i=1:uda.nvid
      % browse for each video file
      pause(0.01); % make sure that the uigetfile executed (MATLAB bug)
      [fname1,pname1] = uigetfile( ...
        {'*.avi;*.cin;*.cine','All movie files (*.avi, *.cin, *.cine)'; ...
        '*.avi','AVI movies (*.avi)'; ...
        '*.cin','Phantom movies (*.cin)'; ...
        '*.cine','Phantom movies (*.cine)'}, ...
        sprintf('Pick movie file %.0d',i));

      pause(0.01); % make sure that the uigetfile executed (MATLAB bug)
      try
        set(h(39+i),'Tag',[pname1,fname1]);
        set(h(39+i),'Userdata',uda);
      catch
        disp('Initialization failed.  Please try again.')
        set(h(2),'deletefcn','');
        close(h(2));
        return
      end
      % change directory
      cd(pname1);
    end

    % Initialize the data arrays
    %
    % set the slider size
    movie1info=mediaInfo([pname1,fname1]);
    if movie1info.NumFrames>1
      set(h(5),'Max',movie1info.NumFrames,'Min',1,'Value',1,'SliderStep', ...
        [1/(movie1info.NumFrames - 1) 1/(movie1info.NumFrames - 1)]);
    else
      set(h(5),'Max',2,'Min',1,'Value',1,'SliderStep',[1 1]);
    end
    % setup the DLTpts, DLTres & offsets arrays
    uda.dltpts(1:movie1info.NumFrames,1:3)=NaN;
    uda.dltres(1:movie1info.NumFrames,1)=NaN;
    uda.offset(1:movie1info.NumFrames,1:uda.nvid)=0;
    % setup the xypts array
    uda.xypts(1:movie1info.NumFrames,1:2*uda.nvid)=NaN;
    % setup the numpts (Number of Points) & currentpoint
    uda.numpts=1; % number of points
    uda.sp=1; % selected point
    uda.recentlysaved=1; % has this data been saved
    uda.reloadVid=false; % force reload of all videos
    uda.predSeed.alpha=0.5; % double exponential predictor initial value
    uda.gapJump=0; % number of "missing data" frames to try and skip over

    figure(h(2)) % make the video figure active

    % plot the first images in each axis
    for i=1:uda.nvid % 1-4 axes, handle indices are 40-43

      % make the axis of interest active and visible
      set(h(i+39),'Visible','on');
      set(h(2),'CurrentAxes',h(i+39));
      tag=get(h(i+39),'Tag');
      ud=get(h(i+39),'Userdata');

      % read the video frame; assume it is grayscale
      movname=get(h(i+39),'Tag');
      mov=mediaRead(movname,1,false); % grab the 1st frame

      % store the movie frame sizes
      uda.movsizes(i,1)=size(mov.cdata,1);
      uda.movsizes(i,2)=size(mov.cdata,2);

      % plot the frame
      redlakeplot(mov.cdata(:,:),h(i+39));
      uda.cdata{i}=mov.cdata; % cache the image

      set(gca,'XTickLabel','');
      set(gca,'YTickLabel','');
      set(h(i+39),'Tag',tag);
      set(h(i+39),'Userdata',ud);
      set(get(h(i+39),'Children'),'ButtonDownFcn','DLTdv3(3)');
      set(get(h(i+39),'Children'),'UserData',ud);

      % set the current frame number
      uda.currframe(i,1)=1; % defaults to 1 in this case

      % store an initial drawVid value
      uda.drawVid(i)=true;
    end

    % query for calibrated cameras and load the DLT coefficients

    if uda.nvid>1
      dlt=questdlg('Are these cameras calibrated via DLT?','Use DLT?', ...
        'yes','no','yes');

      switch dlt % setup DLT coefficients of desired
        case 'yes'
          pause(0.01); % make sure that the uigetfile executed (MATLAB bug)
          [fname1,pname1]=...
            uigetfile('*.csv','Pick the DLT coefficients file');
          pause(0.01); % make sure that the uigetfile executed (MATLAB bug)
          uda.dltcoef=dlmread([pname1,fname1],',');
          uda.dltcoef=uda.dltcoef(:,1:uda.nvid); % prune to # of videos
          uda.dlt=1; % DLT on
          set(h(53),'enable','on')
          set(h(61),'enable','on') % residual threshold
        case 'no'
          uda.dlt=0; % DLT off
      end

    else
      uda.dlt=0; % DLT off (if uda.nvid~>1)
    end

    % turn on the other controls
    set(h(5),'enable','on'); % frame slider
    set(h(7),'enable','on'); % save button
    set(h(8),'enable','on'); % frame number text box
    set(h(12),'enable','on'); % display color video checkbox
    set(h(13),'enable','on'); % video gamma control
    set(h(19),'enable','on'); % add point button
    set(h(22),'enable','on'); % load previous data button
    set(h(32),'enable','on'); % point # pulldown menu
    set(h(35),'enable','on'); % autotrack pulldown menu
    set(h(38),'enable','on'); % autotrack search area size textbox
    set(h(39),'enable','on'); % autotrack threshold textbox
    set(h(57),'enable','on'); % autotrack mode pull-down menu

    % turn on only the appropriate offset controls
    for i=15:13+uda.nvid % turn on one less than the # of videos
      set(h(i),'enable','on'); % video offsets
    end

    % turn on Centroid finding & set value to "On" if the image analysis
    % toolbox functions that it depends on are available
    if exist('im2bw','file')==2 && exist('regionprops','file')==2 && ...
        exist('bwlabel','file')==2
      set(h(55),'enable','on','Value',0);
      disp('Detected Image Analysis toolbox, centroid localization is')
      disp('available, enable it via the checkbox in the Controls window.')
    else
      disp('The Image Analysis toolbox is not available, centroid ')
      disp('localization has been disabled.')
    end

    % if more than 1 video, enable to video updating checkbox
    if uda.nvid >1
      set(h(63),'enable','on');
    end

    % turn off the Initialize button
    set(h(6),'enable','off');

    % write the userdata back
    uda.handles=h; % copy in new handles
    set(h(1),'Userdata',uda);

    % call self to update the string fields
    DLTdv3(4,uda);

%% case 1 - refresh video frames
  case {1} % refresh the video frames

    colorVal=get(h(12),'Value'); % get color mode info

    if strcmp(get(h(6),'enable'),'off')==1 % if initialized
      fr=round(get(h(5),'Value')); % get the frame # from the slider
      set(h(5),'Value',fr); % set the rounded value back
      frmax=get(h(5),'Max'); % get the slider max

      % loop through each axes and update it if appropriate
      for i=1:uda.nvid
        % check to see if we should update this axis
        if uda.drawVid(i)==true || get(h(63),'Value')==true
          % make the axis of interest active
          set(h(2),'CurrentAxes',h(i+39));
          tag=get(h(i+39),'Tag');
          ud=get(h(i+39),'Userdata');
          xl=xlim(h(i+39));
          yl=ylim(h(i+39));

          % read the offset if not the final camera
          if i>1
            offset=str2double(get(h(i+13),'String'));
          else
            offset=0;
          end

          % write the offset
          uda.offset(fr,i)=offset;

          % read the video frame if possible and/or necessary
          if fr+offset <= 0 || fr+offset>frmax
            % no image available
            mov.cdata=chex(1,round(xl(2)),round(yl(2)));
            uda.cdata{i}=mov.cdata;  % cache the image

          elseif fr+offset ~= uda.currframe(i) || uda.reloadVid==true
            % need new image from file
            try
              mov=mediaRead(tag,fr+offset,get(h(12),'Value'));
            catch
              mov.cdata=chex(1,round(xl(2)),round(yl(2)));
            end
            uda.cdata{i}=mov.cdata;  % cache the image

          else
            % image already in memory
            mov.cdata=uda.cdata{i};
          end

          % plot the frame parameters
          hold(h(39+i),'off')
          if colorVal==0 %gray
            redlakeplot(mov.cdata(:,:,1),h(i+39));
          elseif colorVal==1 && size(mov.cdata,3)==1 % color w/ gray video
            redlakeplot(repmat(mov.cdata(:,:,1)+(1-get(h(13),'Value') ...
              )*128,[1,1,3]),h(i+39));
          else % color display with color video
            % do the gamma scaling - since truecolor images don't have a
            % colormap, it is not possible to do quick nonlinear transforms
            % on the colormap instead of the image data itself.  Therefore,
            % we're forced to just do linear scaling - i.e. change the
            % image brightness
            cdata=mov.cdata+(1-get(h(13),'Value'))*128;

            redlakeplot(cdata,h(i+39));
          end

          uda.currframe(i)=fr+offset;
          set((h(i+39)),'XTickLabel','');
          set((h(i+39)),'YTickLabel','');
          set(h(i+39),'Tag',tag)
          set(h(i+39),'Userdata',ud);
          set(get(h(i+39),'Children'),'ButtonDownFcn','DLTdv3(3)');
          set(get(h(i+39),'Children'),'UserData',ud);
          xlim(h(i+39),xl); ylim(h(i+39),yl); % restore axis zoom
          hold on
        end

      end % end for loop through the video axes

      % set the figure gamma for grayscale inputs
      if colorVal==0 % gray
        c=colormap(gray(256));
        cnew=c.^get(h(13),'Value');
        colormap(h(i+39),cnew);
      end

      % call quickRedraw to add the non-image graphics
      quickRedraw(uda,h,sp,fr);
      
      % set the force redraw switch to false
      uda.reloadVid=false;

      % write back any modifications to the main figure userdata
      set(h(1),'Userdata',uda);

      % call self to update the text fields
      DLTdv3(4,uda);
    end

%% case 2 - key press calback
  case {2} % handle keypresses in the figure window - zoom & unzoom axes
    cc=get(h(2),'CurrentCharacter'); % the key pressed
    pl=get(0,'PointerLocation'); % pointer location on the screen
    pos=get(h(2),'Position'); % get the figure position
    fr=round(get(h(5),'Value')); % get the current frame

    % calculate pointer location in normalized units
    plocal=[(pl(1)-pos(1,1)+1)/pos(1,3), (pl(2)-pos(1,2)+1)/pos(1,4)];

    % if the keypress is empty or is a lower-case x, shut off the
    % auto-tracker
    if isempty(cc)
      return
    elseif cc=='x'
      uda.drawVid(:)=true;
      if get(h(35),'Value')<4
        set(h(35),'Value',get(h(35),'Value')+1);
      else
        set(h(35),'Value',1);
      end
      set(h(1),'Userdata',uda);
      return
    elseif cc=='X'
      set(h(35),'Value',5);
      return

    else
      % find which axis (if any) the key press occurred in
      if uda.nvid==1
        if plocal(1)<=0.99 && plocal(2)<=0.99, axh=h(40); vnum=1;
        else disp('The mouse pointer is not over a video.'); return
        end
      elseif uda.nvid==2
        if plocal(1)<=.48 && plocal(2)<=0.99, axh=h(40); vnum=1;
        elseif plocal(1)>=.52 && plocal(2)<=0.99, axh=h(41); vnum=2;
        else disp('The mouse pointer is not over a video.'); return
        end
      elseif uda.nvid==3
        if plocal(1)<=.48 && plocal(2)>=.52, axh=h(40); vnum=1;
        elseif plocal(1)>=.52 && plocal(2)>=.52, axh=h(41); vnum=2;
        elseif plocal(1)<=.48 && plocal(2)<=.48, axh=h(42); vnum=3;
        else disp('The mouse pointer is not over a video.'); return
        end
      elseif uda.nvid==4
        if plocal(1)<=.48 && plocal(2)>=.52, axh=h(40); vnum=1;
        elseif plocal(1)>=.52 && plocal(2)>=.52, axh=h(41); vnum=2;
        elseif plocal(1)<=.48 && plocal(2)<=.48, axh=h(42); vnum=3;
        elseif plocal(1)>=.52 && plocal(2)<=.48, axh=h(43); vnum=4;
        else disp('The mouse pointer is not over a video.'); return
        end
      end
    end

    % process the key press
    if (cc=='=' || cc=='-' || cc=='r') && axh~=0; % check for zoom keys

      % zoom in or out as indicated
      if axh~=0
        set(h(2),'CurrentAxes',axh); % set the current axis
        axpos=get(axh,'Position'); % axis position in figure
        xl=xlim; yl=ylim; % x & y limits on axis
        % calculate the normalized position within the axis
        plocal2=[(plocal(1)-axpos(1,1))/axpos(1,3) (plocal(2) ...
          -axpos(1,2))/axpos(1,4)];

        % calculate the actual pixel postion of the pointer
        pixpos=round([(xl(2)-xl(1))*plocal2(1)+xl(1) ...
          (yl(2)-yl(1))*plocal2(2)+yl(1)]);

        % axis location in pixels (idealized)
        axpix(3)=pos(3)*axpos(3);
        axpix(4)=pos(4)*axpos(4);

        % adjust pixels for distortion due to normalized axes
        xRatio=(axpix(3)/axpix(4))/(diff(xl)/diff(yl));
        yRatio=(axpix(4)/axpix(3))/(diff(yl)/diff(xl));
        if xRatio > 1
          xmp=xl(1)+(xl(2)-xl(1))/2;
          xmpd=pixpos(1)-xmp;
          pixpos(1)=pixpos(1)+xmpd*(xRatio-1);
        elseif yRatio > 1
          ymp=yl(1)+(yl(2)-yl(1))/2;
          ympd=pixpos(2)-ymp;
          pixpos(2)=pixpos(2)+ympd*(yRatio-1);
        end

        % set the figure xlimit and ylimit
        if cc=='=' % zoom in
          xlim([pixpos(1)-(xl(2)-xl(1))/3 pixpos(1)+(xl(2)-xl(1))/3]);
          ylim([pixpos(2)-(yl(2)-yl(1))/3 pixpos(2)+(yl(2)-yl(1))/3]);
        elseif cc=='-' % zoom out
          xlim([pixpos(1)-(xl(2)-xl(1))/1.5 pixpos(1)+(xl(2)-xl(1))/1.5]);
          ylim([pixpos(2)-(yl(2)-yl(1))/1.5 pixpos(2)+(yl(2)-yl(1))/1.5]);
        else % restore zoom
          xlim([0 uda.movsizes(vnum,2)]);
          ylim([0 uda.movsizes(vnum,1)]);
        end

        % set drawnow for the axis in question
        uda.drawVid(vnum)=true;

      end

    % check for valid movement keys  
    elseif cc=='f' || cc=='b' || cc=='F' || cc=='B' && axh~=0 
      fr=round(get(h(5),'Value')); % get current slider value
      smax=get(h(5),'Max'); % max slider value
      smin=get(h(5),'Min'); % max slider value
      axn=find(h==axh)-39; % axis number
      if isnan(axn),
        disp('Error: The mouse pointer is not in an axis.')
        return
      end
      cp=uda.xypts(fr,axn*2-1:axn*2,sp); % set current point to xy value
      if cc=='f' && fr+1 <= smax
        if (get(h(35),'Value')==3 || get(h(35),'Value')==5) ...
            && isnan(cp(1))==0 % semi-auto tracking
          keyadvance=1; % set keyadvance variable for DLTautotrack function
          uda=DLTautotrack2fun(uda,h,keyadvance,axn,cp,fr,sp);
        end
        set(h(5),'Value',fr+1); % current frame + 1
        fr=fr+1;
      elseif cc=='b' && fr-1 >= smin
        set(h(5),'Value',fr-1); % current frame - 1
        fr=fr-1;
      elseif cc=='F' && fr+50 < smax
        set(h(5),'Value',fr+50); % current frame + 50
        fr=fr+50;
      elseif cc=='B' && fr-50 >= smin
        set(h(5),'Value',fr-50); % current frame - 50
        fr=fr-50;
      end

      % full redraw of the screen
      DLTdv3(1,uda);

      % update the control / zoom window
      % 1st retrieve the cp from the data file in case the autotracker
      % changed it
      cp=uda.xypts(fr,axn*2-1:axn*2,sp);
      updateSmallPlot(h,axn,cp);

    elseif cc=='n' % add a new point
      yesNo=questdlg('Are you sure you want to add a point?',...
        'Add a point?','Yes','No','No');
      if strcmp(yesNo,'Yes')==1
        DLTdv3(12,uda);
        return
      else
        return
      end

    elseif cc=='.' || cc==',' % change point
      % get current pull-down list (available points)
      ptnum=numel(get(h(32),'String'))/2; % need str2num here
      ptval=get(h(32),'Value'); % selected point
      if cc==',' && ptval>1 % decrease point value if able
        set(h(32),'Value',ptval-1);
        ptval=ptval-1;
      elseif cc=='.' && ptval<ptnum % increase pt value if able
        set(h(32),'Value',ptval+1);
        ptval=ptval+1;
      end

      pt=uda.xypts(fr,vnum*2-1:vnum*2,ptval);

      % update the magnified point view
      updateSmallPlot(h,vnum,pt);

      % do a quick screen redraw
      quickRedraw(uda,h,ptval,fr);

    elseif cc=='i' || cc=='j' || cc=='k' || cc=='m' || cc=='4' || ...
        cc=='8' || cc=='6' || cc=='2' % nudge point
      % check and see if there is a point to nudge, get it's value if
      % possible
      if isnan(uda.xypts(fr,vnum*2-1,sp))
        return
      else
        pt=uda.xypts(fr,vnum*2-1:vnum*2,sp);
      end

      % modify pt based on the 'nudge' value
      nudge=0.5; % 1/2 pixel nudge
      if cc=='i' || cc=='8'
        pt(1,2)=pt(1,2)+nudge; % up
      elseif cc=='j' || cc=='4'
        pt(1,1)=pt(1,1)-nudge; % left
      elseif cc=='k' || cc=='6'
        pt(1,1)=pt(1,1)+nudge; % right
      else
        pt(1,2)=pt(1,2)-nudge; % down
      end

      % set the modified point
      uda.xypts(fr,vnum*2-1:vnum*2,sp)=pt;

      % DLT update
      if sum(isnan(uda.xypts(fr,:,sp))-1)<=-4 && uda.dlt==1 % 2+ xy pts
        [xyz,res]=dlt_reconstruct(uda.dltcoef,uda.xypts(fr,:,sp)); % DLT
        uda.dltpts(fr,1:3,sp)=xyz(1:3); % store the DLT points
        uda.dltres(fr,1,sp)=res; % store the DLT residual
      else
        uda.dltpts(fr,1:3,sp)=NaN; % set DLT points to NaN
        uda.dltres(fr,1,sp)=NaN; % set DLT residuals to NaN
      end

      % update the magnified point view
      updateSmallPlot(h,vnum,pt);

      % do a quick screen redraw
      quickRedraw(uda,h,sp,fr);

    elseif cc==' ' % space bar (digitize a point)
      set(h(2),'CurrentAxes',axh); % set the current axis
      axpos=get(axh,'Position'); % axis position in figure
      xl=xlim; yl=ylim; % x & y limits on axis
      % calculate the normalized position within the axis
      plocal2=[(plocal(1)-axpos(1,1))/axpos(1,3) (plocal(2) ...
        -axpos(1,2))/axpos(1,4)];

      % calculate the actual pixel postion of the pointer
      pixpos=([(xl(2)-xl(1)+0)*plocal2(1)+xl(1) ...
        (yl(2)-yl(1)+0)*plocal2(2)+yl(1)]);

      % axis location in pixels (idealized)
      axpix(3)=pos(3)*axpos(3);
      axpix(4)=pos(4)*axpos(4);

      % adjust pixels for distortion due to normalized axes
      xRatio=(axpix(3)/axpix(4))/(diff(xl)/diff(yl));
      yRatio=(axpix(4)/axpix(3))/(diff(yl)/diff(xl));
      if xRatio > 1
        xmp=xl(1)+(xl(2)-xl(1))/2;
        xmpd=pixpos(1)-xmp;
        pixpos(1)=pixpos(1)+xmpd*(xRatio-1);
      elseif yRatio > 1
        ymp=yl(1)+(yl(2)-yl(1))/2;
        ympd=pixpos(2)-ymp;
        pixpos(2)=pixpos(2)+ympd*(yRatio-1);
      end

      % setup oData for the digitization routine
      oData.seltype='standard';
      oData.cp=pixpos;
      oData.axn=vnum;
      DLTdv3(3,uda,oData); % digitize a point
      return

    elseif cc=='z' % delete the current point
      oData.seltype='alt';
      oData.cp=[NaN,NaN];
      oData.axn=vnum;
      DLTdv3(3,uda,oData); % digitize a point
      return

    elseif cc=='R' % recompute 3D locations
      disp('Recomputing all 3D coordinates.')
      for i=1:size(uda.xypts,3)
        [rawResults,rawRes]=dlt_reconstruct(uda.dltcoef,uda.xypts(:,:,i));
        uda.dltpts(:,:,i)=rawResults(:,1:3);
        uda.dltres(:,:,i)=rawRes;
      end

    else

    end % end of main keypress evaluation loop

    % write back any modifications to the main figure userdata
    set(h(1),'Userdata',uda);

%% case 3 - mouse click on image callback
  case {3} % handle button clicks in axes
    % disp('case 3: handle button clicks')

    if strcmp(get(gcbo,'Tag'),'VideoFigure')
      % entered the function via space bar, not mouse click
      seltype=oData.seltype;
      axn=oData.axn;
      cp=oData.cp;
    else
      % entered via mouse click
      set(h(2),'CurrentAxes',get(gcbo,'Parent')); % set the current axis
      cp=get(get(gcbo,'Parent'),'CurrentPoint'); % get the xy coordinates
      seltype=cellstr(get(h(2),'SelectionType')); % selection type
      axn=find(h==get(gcbo,'Parent'))-39; % axis number
    end
    fr=round(get(h(5),'Value')); % get the current frame

    % different actions depend on selection types
    if strcmp(seltype,'alt')==true || strcmp(seltype,'normal')==true
      % set NaN point for right click
      if strcmp(seltype,'alt')==true
        cp(:,:)=NaN;
        % scan for centroid if left click & GUI option set
      elseif strcmp(seltype,'normal') && get(h(55),'Value')==true
        [cp]=click2centroid(h,cp,axn);
      end

      % set the points for the current frame
      uda.xypts(fr,axn*2-1,sp)=cp(1,1); % set x point
      uda.xypts(fr,axn*2,sp)=cp(1,2); % set y point

      % DLT update if 2 or more xy pts
      if sum(isnan(uda.xypts(fr,:,sp))-1)<=-4 && uda.dlt==1
        [xyz,res]=dlt_reconstruct(uda.dltcoef,uda.xypts(fr,:,sp));
        uda.dltpts(fr,1:3,sp)=xyz(1:3); % get the DLT points
        uda.dltres(fr,1,sp)=res; % get the DLT residual
      else
        uda.dltpts(fr,1:3,sp)=NaN; % set DLT points to NaN
        uda.dltres(fr,1,sp)=NaN; % set DLT residuals to NaN
      end

      % new data available, change the recently saved parameter to false
      uda.recentlysaved=0;

      % zoomed window update
      updateSmallPlot(h,axn,cp);

      set(h(1),'Userdata',uda); % pass back complete user data

      % quick screen refresh to show the new point & possibly DLT info
      quickRedraw(uda,h,sp,fr);
    end % end of click selection type processing for normal & alt clicks

    % process auto-tracker options that depend on click
    autoT=get(h(35),'Value'); % 1=off, 2=advance, 3=semi, 4=auto, 5=multi
    if strcmp(seltype,'normal')==true && autoT>1
      if autoT==2 && fr<get(h(5),'Max'); % auto-advance
        set(h(5),'Value',fr+1); % current frame + 1
        fr=fr+1;
        % full redraw of the screen
        DLTdv3(1,uda);
        % update the control / zoom window
        cp=uda.xypts(fr,axn*2-1:axn*2,sp);
        updateSmallPlot(h,axn,cp);
      elseif autoT>2 && autoT<5
        keyadvance=0; % set keyadvance variable for DLTautotrack2
        DLTautotrack2fun(uda,h,keyadvance,axn,cp,fr,sp);
      end
    elseif strcmp(seltype,'extend')==true && autoT==5;
      keyadvance=2; % set keyadvance variable for DLTautotrack function
      axn=1; % default axis
      [uda]=DLTautotrack2fun(uda,h,keyadvance,axn,cp,fr,sp);

      % full redraw of the screen
      DLTdv3(1,uda);
    end

%% case 4 - update GUI text fields
  case {4}	% update the text fields
    % set the frame # string
    fr=round(get(h(5),'Value')); % get current frame & max from the slider
    frmax=get(h(5),'Max');
    set(h(21),'String',['/' num2str(frmax)]);
    set(h(8),'String',num2str(fr));

    % set the DLT residual
    if uda.dlt
      set(h(33),'String',['DLT residual: ' num2str(uda.dltres(fr,1,sp))]);
    end


%% case 5 - save data button
  case {5} % save data

    % get a place to save it
    pname=uigetdir(pwd,'Pick a directory to contain the output files');
    pause(0.1); % make sure that the uigetdir executed (MATLAB bug)

    % get a prefix
    pfix=inputdlg({'Enter a prefix for the data files'},...
      'Data prefix',1,{'trial01'});
    if numel(pfix)==0
      return
    else
      pfix=pfix{1};
    end

    % test for existing files
    if exist([pname,filesep,pfix,'xyzpts.csv'],'file')~=0
      overwrite=questdlg('Overwrite existing data?', ...
        'Overwrite?','Yes','No','No');
    else
      overwrite='Yes';
    end

    % create headers (dltpts)
    dlth=cell(3*size(uda.dltpts,3),1);
    for i=1:size(uda.dltpts,3)
      dlth{i*3-2}=sprintf('pt%s_X',num2str(i));
      dlth{i*3-1}=sprintf('pt%s_Y',num2str(i));
      dlth{i*3-0}=sprintf('pt%s_Z',num2str(i));
    end

    % create headers (dltres)
    dlthr=cell(size(uda.dltpts,3),1);
    for i=1:size(uda.dltpts,3)
      dlthr{i}=sprintf('pt%s_dltres',num2str(i));
    end

    % create headers (xypts)
    numPts=size(uda.dltpts,3);
    xyh=cell(uda.nvid*numPts*2,1);
    for i=1:numPts
      for j=1:uda.nvid
        xyh{(i-1)*uda.nvid*2+(j*2-1)}=...
          sprintf('pt%s_cam%s_X',num2str(i),num2str(j));
        xyh{(i-1)*uda.nvid*2+(j*2)}=...
          sprintf('pt%s_cam%s_Y',num2str(i),num2str(j));
      end
    end

    % create headers (offset)
    offh=cell(uda.nvid,1);
    for i=1:uda.nvid
      offh{i}=sprintf('cam%s_offset',num2str(i));
    end

    if strcmp(overwrite,'Yes')==1
      % dltpts
      f1=fopen([pname,filesep,pfix,'xyzpts.csv'],'w');
      % header
      for i=1:numel(dlth)-1
        fprintf(f1,'%s,',dlth{i});
      end
      fprintf(f1,'%s\n',dlth{end});

      % data
      for i=1:size(uda.dltpts,1);
        tempData=squeeze(uda.dltpts(i,:,:));
        for j=1:numel(tempData)-1
          fprintf(f1,'%.6f,',tempData(j));
        end
        fprintf(f1,'%.6f\n',tempData(end));
      end
      fclose(f1);

      % xypts
      f1=fopen([pname,filesep,pfix,'xypts.csv'],'w');
      % header
      for i=1:numel(xyh)-1
        fprintf(f1,'%s,',xyh{i});
      end
      fprintf(f1,'%s\n',xyh{end});
      % data
      for i=1:size(uda.xypts,1);
        tempData=squeeze(uda.xypts(i,:,:));
        for j=1:numel(tempData)-1
          fprintf(f1,'%.6f,',tempData(j));
        end
        fprintf(f1,'%.6f\n',tempData(end));
      end
      fclose(f1);

      % xyzres
      f1=fopen([pname,filesep,pfix,'xyzres.csv'],'w');
      % header
      for i=1:numel(dlthr)-1
        fprintf(f1,'%s,',dlthr{i});
      end
      fprintf(f1,'%s\n',dlthr{end});
      % data
      for i=1:size(uda.dltres,1);
        tempData=squeeze(uda.dltres(i,:,:));
        for j=1:numel(tempData)-1
          fprintf(f1,'%.6f,',tempData(j));
        end
        fprintf(f1,'%.6f\n',tempData(end));
      end
      fclose(f1);

      % offsets
      f1=fopen([pname,filesep,pfix,'offsets.csv'],'w');
      % header
      for i=1:numel(offh)-1
        fprintf(f1,'%s,',offh{i});
      end
      fprintf(f1,'%s\n',offh{end});
      % data
      for i=1:size(uda.offset,1);
        tempData=squeeze(uda.offset(i,:,:));
        for j=1:numel(tempData)-1
          fprintf(f1,'%.6f,',tempData(j));
        end
        fprintf(f1,'%.6f\n',tempData(end));
      end
      fclose(f1);
      
      % check and see if we should create and save confidence intervals
      if uda.dlt
        CIs=questdlg(['Would you like to create 95% confidence inter',...
          'vals? (This can take a while)'],'95% CIs?','yes','no','no');
        pause(0.1); % make sure that the questdlg executed (MATLAB bug)
        if strcmp(CIs,'yes')==1
          minErrs=questdlg(['Would you like to enforce a minimum ',...
            'digitizing error of 1 pixel?'],'minimum error?', ...
            'yes','no','no');
          if strcmp(minErrs,'yes')==1
            minErr=1;
          else
            minErr=0;
          end
          
          tdata=reshape(uda.xypts,size(uda.xypts,1),size(uda.xypts,2)* ...
            size(uda.xypts,3));
          [CI,tol,weights]=dlt_confidenceIntervals(uda.dltcoef,tdata,...
            minErr);
          
          % create headers (xyzCI)
          CIh=cell(3*size(uda.dltpts,3),1);
          for i=1:size(uda.dltpts,3)
            CIh{i*3-2}=sprintf('pt%s_X+-CI',num2str(i));
            CIh{i*3-1}=sprintf('pt%s_Y+-CI',num2str(i));
            CIh{i*3-0}=sprintf('pt%s_Z+-CI',num2str(i));
          end
          
          f1=fopen([pname,filesep,pfix,'xyzCI.csv'],'w');
          % header
          for i=1:numel(CIh)-1
            fprintf(f1,'%s,',CIh{i});
          end
          fprintf(f1,'%s\n',CIh{end});
          % data
          for i=1:size(CI,1);
            for j=1:numel(CI(i,:))-1
              fprintf(f1,'%.6f,',CI(i,j));
            end
            fprintf(f1,'%.6f\n',CI(i,j));
          end
          fclose(f1);
          
          % spline filtered data
          if exist('spaps','file')~=2
            disp(['DLTdv3: The spline toolbox is not available so'...
              ' spline filtered data cannot be created.'])
          else
            % create filtered data
            xyzData=reshape(uda.dltpts,size(uda.dltpts,1), ...
              3*size(uda.dltpts,3));
            xyzData=dlt_splineInterp(xyzData,'linear');
            weights(isnan(weights))=0;
            fData=dlt_splineFilter(xyzData,tol,weights,0);
            fData(weights==0)=NaN;
            
            % create filtered data header
            filtH=cell(3*size(uda.dltpts,3),1);
            for i=1:size(uda.dltpts,3)
              filtH{i*3-2}=sprintf('pt%sfilt_X',num2str(i));
              filtH{i*3-1}=sprintf('pt%sfilt_Y',num2str(i));
              filtH{i*3-0}=sprintf('pt%sfilt_Z',num2str(i));
            end
            
            % save the data file
            f1=fopen([pname,filesep,pfix,'xyzFilt.csv'],'w');
            % header
            for i=1:numel(filtH)-1
              fprintf(f1,'%s,',filtH{i});
            end
            fprintf(f1,'%s\n',filtH{end});
            % data
            for i=1:size(fData,1);
              for j=1:numel(fData(i,:))-1
                fprintf(f1,'%.6f,',fData(i,j));
              end
              fprintf(f1,'%.6f\n',fData(i,j+1));
            end
            fclose(f1);
          end
        end
      end

      uda.recentlysaved=1;
      set(h(1),'Userdata',uda); % pass back complete user data

      msgbox('Data saved.');
    end

%% case 6 - load points button
  case {6} % load previously saved points
    % load the xy points file
    [fname1,pname1]=...
      uigetfile('*xypts.csv','Select the [prefix]xypts.csv file');
    pause(0.1); % make sure that the uigetfile executed (MATLAB bug)
    pfix=[pname1,fname1];
    pfix(end-8:end)=[]; % remove the 'xypts.csv' portion

    % load the exported dlt points
    tempData=dlmread([pfix,'xyzpts.csv'],',',1,0);
    len=size(tempData,1);
    numpts=size(tempData,2)/3; % number of points
    % reshape to final uda.dltpts size
    uda.dltpts=reshape(tempData,len,3,numpts);

    % load the exported dlt residuals
    tempData=dlmread([pfix,'xyzres.csv'],',',1,0);
    uda.dltres=reshape(tempData,len,1,numpts); % reshape to uda.dltres size

    % load the exported xy points
    tempData=dlmread([pfix,'xypts.csv'],',',1,0);
    uda.xypts=reshape(tempData,len,size(tempData,2)/numpts,numpts);

    % load the exported offset
    uda.offset=dlmread([pfix,'offsets.csv'],',',1,0);

    % check for similarity with video data
    newsize=size(uda.xypts,1); % size of the new points data
    oldsize=size(uda.offset,1); % offset size was set by # of frames
    newwidth=size(uda.xypts,2); % width of new data file
    if newsize~=oldsize || newwidth~=uda.nvid*2
      msgbox(['WARNING - the digitized point file size does not match',...
        'video frames, aborting.'], ...
        'Warning','warn','modal')
      return
    end

    % set offsets in the text boxes to their average (non-zero) values from
    % the offsets file, then warn the user
    for i=2:uda.nvid
      idx=find(uda.offset(:,i)~=0);
      if numel(idx)==0
        % offset is zero
        set(h(i+13),'String','0');
      else
        offset=round(inanmean(uda.offset(idx,i)));
        set(h(i+13),'String',num2str(offset));
      end
    end
    msgbox(['WARNING - check the offset values, they may not be correct'...
      ,'for partially digitizied files.'], ...
      'Warning','warn','modal')

    % update the number of points settings
    uda.numpts=numpts;
    ptstring=char(ones(1,numpts*2+numpts-1));
    for i=1:uda.numpts-1
      ptstring(1,i*3-2:i*3)=sprintf('%2d|',i);
    end
    ptstring(1,numpts*3-2:numpts*3-1)=sprintf('%2d',numpts);
    set(h(32),'String',ptstring);

    % call self to update the video fields
    DLTdv3(1,uda);

%% case 7 - frame selection text box
  case {7} % frame text box
    % get and validate input
    newFrame=str2double(get(h(8),'String'));
    frmax=get(h(5),'Max');
    curFrame=get(h(5),'Value');
    if isempty(newFrame) || isnan(newFrame)
      set(h(8),'String',num2str(curFrame));
      return
    elseif newFrame < 1
      newFrame=1;
    elseif newFrame > frmax
      newFrame=frmax;
    else
      newFrame=round(newFrame);
    end

    % apply new frame number by setting the slider and making a recursive
    % call to the frame update code
    set(h(5),'Value',newFrame)
    DLTdv3(1,uda);
    return

%% case 8 - validate video offsets text
  case {8} % validate the video offsets text
    % disp('case 8: validate the video offsets text')
    offset=str2double(get(gcbo,'String'));
    if mod(offset,1)~=0 % mod 1 will return 0 for integers
      beep % warn the user
      disp('Corrected invalid input, video offsets must be integers')
      set(gcbo,'String',num2str(round(offset))); % round the offset
    elseif isempty(offset)
      beep
      disp('Corrected invalid input, video offsets must be integers')
      set(gcbo,'String','0'); % set the offset to zero
    end
    DLTdv3(1,uda); % call self to update video frames

%% case 9 - validate autotrack search width
  case {9} % validate autotrack search width
    % disp('case 9: validate the autotrack search width')
    atwidth=str2double(get(gcbo,'String'));
    if atwidth>0 && mod(atwidth,1)==0 && isempty(atwidth)==0
      % input okay
    else
      beep
      disp('Auto-track width should be a positive integer')
      set(gcbo,'String','9')
    end

%% case 10 - validate autotrack threshold
  case {10} % validate autotrack threshold

    % disp('case 10: validate the autotrack threshold')
    thold=str2double(get(gcbo,'String'));
    if thold>=0 || isnan(thold)
      % input okay
    else
      beep
      disp('Auto-track threshold should be a positive real number or NaN')
      set(gcbo,'String','10')
    end

%% case 11 - Quit button
  case {11} % Quit button

    reallyquit=...
      questdlg('Are you sure you want to quit?','Quit?','yes','no','no');
    pause(0.1); % make sure that the questdlg executed (MATLAB bug)
    if strcmp(reallyquit,'yes')==1
      try
        close(h(2));
      catch
      end
      try
        close(h(1));
      catch
      end
    end

%% case 12 - Add-a-point button
  case {12} % add-a-point button
    uda.numpts=uda.numpts+1; % update number of points
    ptstring=get(h(32),'String'); % get current pull-down list
    % update pull-down list string
    if uda.numpts<3
      ptstring=[ptstring,'|',sprintf('%2d',uda.numpts)];
    else
      ptstring(end+1,:)=sprintf('%2d',uda.numpts);
    end
    set(h(32),'String',ptstring); % write updated list back
    set(h(32),'Value',uda.numpts(end)); % update value to the new point

    % update the data matrices by adding the new dimension
    uda.xypts(:,:,uda.numpts)=NaN;
    uda.dltpts(:,:,uda.numpts)=NaN;
    uda.dltres(:,:,uda.numpts)=NaN;

    set(h(1),'Userdata',uda); % write the new userdata back

    DLTdv3(1,uda); % call self to update video frames

%% case 13 - Window close via non-Matlab method
  case {13} % Window close via non-Matlab method
    % if initialization completed and there is data to save
    if h(2)~=0 && uda.recentlysaved==0;
      savefirst= ...
        questdlg('Would you like to save your data before you quit?', ...
        'Save first?','yes','no','yes');
      pause(0.1); % make sure that the questdlg executed (MATLAB bug)
      if strcmp(savefirst,'yes')
        DLTdv3(5,uda); % call self to save data
      else
        uda.recentlysaved=1; % mark the data saved to avoid a 2nd check
        set(h(1),'Userdata',uda); % write the new userdata back
      end
    end
    try
      delete(h(2));
    catch
    end
    try
      delete(h(1));
    catch
    end

%% case 14 - Centroid finding checkbox
  case {14} % Click / unclick Centroid finding checkbox
    % enable or disable color menu
    if get(h(55),'Value')==1
      set(h(59),'enable','on')
    else
      set(h(59),'enable','off')
    end
    
%% case 15 - Color video checkbox
  case {15} % Click / unclick color video checkbox
    if get(h(12),'Value')==0
      set(h(55),'enable','on')
      set(h(59),'enable','on')
    else
      set(h(55),'value',false)
      set(h(55),'enable','off')
      set(h(59),'enable','off')
    end
    uda.reloadVid=true; % force video reload in next redraw
    DLTdv3(1,uda); % redraw screen

end % end of switch / case statement

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Begin subfunctions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% redlakeplot

function [h] = redlakeplot(varargin)

% function [h] = redlakeplot(image,ax)
%
% Description:	Quick function to plot images in an axis
%
% Version history:
% 1.0 - Ty Hedrick 3/5/2002 - initial version

if nargin ~= 2
  disp('redlakeplot: Incorrect number of inputs.')
  return
end

ax=varargin{2};

h=image(varargin{1},'CDataMapping','scaled','parent',ax);

set(h,'EraseMode','normal');
colormap(gray(256))
axis(ax,'xy')
axis(ax,'equal')
hold(ax,'on')
ha=get(h,'Parent');
set(ha,'XTick',[],'YTick',[],'XColor',[0.8314 0.8157 0.7843],'YColor', ...
  [0.8314 0.8157 0.7843],'Color',[0.8314 0.8157 0.7843]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% updateSmallPlot

function updateSmallPlot(h,vnum,cp,roi)

% update the magnified plot in the "Controls" window.  If the cp input is a
% NaN the function displays a checkerboard, if roi is not given the
% function grabs one from the appropriate plot using the other included
% information.

if isnan(cp(1))
  roi=chex(1,21,21).*255;
end

x=round(cp(1,1)); % get an integer X point
y=round(cp(1,2)); % get an integer Y point
psize=round(str2double(get(h(38),'String'))); % search area size

if exist('roi','var')~=1 % don't have roi yet, go get it
  psize=round(str2double(get(h(38),'String'))); % search area size
  kids=get(h(vnum+39),'Children'); % children of current axis
  imdat=get(kids(end),'CData'); % read current image
  try
    roi=imdat(y-psize:y+psize,x-psize:x+psize,:);
  catch
    return
  end
end

if isnan(roi(1))
  return
end

% update the roi viewer in the controls frame
delete(get(h(51),'Children'))

% scale roi to gamma
gamma=get(h(13),'Value');
if size(roi,3)==1 % grayscale
  roi2=(double(roi).^gamma).*(255/255^gamma);
  image('Parent',h(51),'Cdata',roi2,'CDataMapping','scaled');
else % color
  roi2=roi+(1-gamma)*128;
  image('Parent',h(51),'Cdata',roi2);
end

edgelen=size(roi,1);
xlim(h(51),[1 edgelen]);
ylim(h(51),[1 edgelen]);

% put a crosshair on the target image
hold(h(51),'on')
plot(h(51),[1;2*psize+1],[psize+1+cp(1,2)-y,psize+1+cp(1,2)-y],'r-');
plot(h(51),[psize+1+cp(1,1)-x,psize+1+cp(1,1)-x],[1;2*psize+1],'r-');
hold(h(51),'off')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% partialdlt

function [m,b]=partialdlt(u,v,C1,C2)

% function [m,b]=partialdlt(u,v,C1,C2)
%
% partialdlt takes as inputs a set of X,Y coordinates from one camera view
% and the DLT coefficients for the view and one additional view.  It
% returns the line coefficients m & b for Y=mX+b in the 2nd camera view.
% Under error-free DLT, the X,Y marker in the 2nd camera view must fall
% along the line given.
%
% Inputs:
%	u = X coordinate in camera 1
%	v = Y coordinate in camera 1
%	C1 = the 11 dlt coefficients for camera 1
%	C2 = the 11 dlt coefficients for camera 2
%
% Outputs:
%	m = slope of the line in camera 2
%	b = Y-intercept of the line in camera 2
%
% Initial version:
% Ty Hedrick, 11/25/03
%	6/14/04 - Ty Hedrick, updated to use the proper solution for x(i)

% pick 2 random Z (actual values are not important)
z(1)=500;
z(2)=-500;

% for each z predict x & y
x=z*NaN;
y=z*NaN;
for i=1:2
  Z=z(i);

  y(i)= -(u*C1(9)*C1(7)*Z + u*C1(9)*C1(8) - u*C1(11)*Z*C1(5) -u*C1(5) + ...
    C1(1)*v*C1(11)*Z + C1(1)*v - C1(1)*C1(7)*Z - C1(1)*C1(8) - ...
    C1(3)*Z*v*C1(9) + C1(3)*Z*C1(5) - C1(4)*v*C1(9) + C1(4)*C1(5)) / ...
    (u*C1(9)*C1(6) - u*C1(10)*C1(5) + C1(1)*v*C1(10) - C1(1)*C1(6) - ...
    C1(2)*v*C1(9) + C1(2)*C1(5));

  Y=y(i);

  x(i)= -(v*C1(10)*Y+v*C1(11)*Z+v-C1(6)*Y-C1(7)*Z-C1(8))/(v*C1(9)-C1(5));
end

% back the points into the cam2 X,Y domain
xy(1:2,1:2)=NaN;
for i=1:2
  xy(i,:)=dlt_inverse(C2(:),[x(i),y(i),z(i)]);
end

% get a line equation back, y=mx+b
m=(xy(2,2)-xy(1,2))/(xy(2,1)-xy(1,1));
b=xy(1,2)-m*xy(1,1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% click2centroid

function [cp]=click2centroid(h,cp,axn,imdat)

% Use the centroid locating tools in the MATLAB image analysis toolbox to
% pull the mouse click to the centroid of a putative marker

psize=round(str2double(get(h(38),'String'))); % search area size

% make sure we have our image data
if exist('imdat','var')==0
  kids=get(h(axn+39),'Children'); % children of current axis
  imdat=get(kids(end),'CData'); % read current image
end
x=round(cp(1,1)); % get an integer X point
y=round(cp(1,2)); % get an integer Y point

% determine the base area around the mouse click to
% grab for centroid finding
try
  roi=double(imdat(y-psize:y+psize,x-psize:x+psize));
catch
  % if tcommand fails return without adjusting cp
  return
end

% apply gamma and rescale
roi=roi.^get(h(13),'Value');
roi=roi-min(min(roi));
roi=roi*(1/max(max(roi)));

% detrend the roibase to try and remove any image-wide edges
roibase=rot90(detrend(rot90(detrend(roi))),-1);

% rescale roibase again following the detrend
roibase=roibase-min(min(roibase));
roibase=roibase*(1/max(max(roibase)));

% threshhold for conversion to binary image
level=graythresh(roibase);

% convert to binary image
roiB=im2bw(roibase,level+(1-level)*0.5);

% create alternative, inverted binary image
roiBi=im2bw(roibase,level/1.5);
roiBi=logical(roiBi*-1+1);

% identify objects
[labeled_roiB]=bwlabel(roiB,4);
[labeled_roiBi]=bwlabel(roiBi,4);

% get object info
roiB_data=regionprops(labeled_roiB,'basic');
roiBi_data=regionprops(labeled_roiBi,'basic');

% for each roi*_data, find the largest object
roiB_sz(1:length(roiB_data))=NaN;
for i=1:length(roiB_data)
  roiB_sz(i)=roiB_data(i).Area;
end
roiB_dx=find(roiB_sz==max(roiB_sz));

roiBi_sz(1:length(roiBi_data))=NaN;
for i=1:length(roiBi_data)
  roiBi_sz(i)=roiBi_data(i).Area;
end
roiBi_dx=find(roiBi_sz==max(roiBi_sz));

% check "white" or "black" option from menu
% 1 == black, 2 == white
whiteBlack=get(h(59),'Value');
if whiteBlack==1
  % black points
  % create weighted centroid from bounding box
  bb=roiBi_data(roiBi_dx(1)).BoundingBox;
  bb(1:2)=ceil(bb(1:2));
  bb(3:4)=(bb(3:4)-1)+bb(1:2);
  blk=1-roibase(bb(2):bb(4),bb(1):bb(3));
  ySeq=(bb(2):bb(4))';
  yWeight=sum(blk,2);
  cY=sum(ySeq.*yWeight)/sum(yWeight);
  xSeq=(bb(1):bb(3));
  xWeight=sum(blk,1);
  cX=sum(xSeq.*xWeight)/sum(xWeight);
  cp(1,1)=cp(1,1)+cX-psize-1;
  cp(1,2)=cp(1,2)+cY-psize-1;

else
  % white points
  % create weighted centroid from bounding box
  bb=roiB_data(roiB_dx(1)).BoundingBox;
  bb(1:2)=ceil(bb(1:2));
  bb(3:4)=(bb(3:4)-1)+bb(1:2);
  blk=roibase(bb(2):bb(4),bb(1):bb(3));
  ySeq=(bb(2):bb(4))';
  yWeight=sum(blk,2);
  cY=sum(ySeq.*yWeight)/sum(yWeight);
  xSeq=(bb(1):bb(3));
  xWeight=sum(blk,1);
  cX=sum(xSeq.*xWeight)/sum(xWeight);
  cp(1,1)=cp(1,1)+cX-psize-1;
  cp(1,2)=cp(1,2)+cY-psize-1;

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% DLTautotrack2fun

function [uda,fr]=DLTautotrack2fun(uda,h,keyadvance,axn,cp,fr,sp)

% DLTautotrack2.m function
%
% This function handles the auto-tracking (both semi and auto mode)
% functions for the DLTdv3.m
%
% Inputs:
%   uda = userdata structure
%   h = handles structure
%   keyadvance = whether or not the function was initiated by a key press
%   axn = axis number of the video in question
%   cp = [x,y] coordinates for the current point
%   fr = # of the current frame
%   sp = # of the selected point (for multi-point tracking)
%
% Version 1, Ty Hedrick, 8/1/04
% Version 2, Ty Hedrick, 9/27/2005

% get/set basic variables
frmax=get(h(5),'Max');
psize=round(str2double(get(h(38),'String'))); % search area size
thold=str2double(get(h(39),'String')); % region match threshold
spReturn=sp; % original selected point
atMode=get(h(35),'Value'); % auto-track mode: 1=off, 2=advance,
% 3=semi, 4=auto, 5=multi
trackFailed=false; % tracking loop pass / fail marker

% make sure we're not already at the end of the sequence
if fr==frmax, return, end

% set all axes to draw off
uda.drawVid(:)=false;

% setup axn (axis number) matrix
if atMode==5 % multi-mode
  AAxn=1:uda.nvid;
  axnReturn=1; % assumed original axis
else % any other mode
  AAxn=axn;
  uda.drawVid(axn)=true;
  axnReturn=axn; % original axis
end

% setup base matching image areas
% loop through each axis
for A=1:numel(AAxn)
  axn=AAxn(A); % set the working axis

  % extract image
  kids=get(h(axn+39),'Children'); % children of current axis
  imdat=get(kids(end),'CData'); % read current image

  % setup spM (selected point matrix) for this video axis
  spM(1,axn)=0;
  if atMode==5 % multi-mode
    spInc=1; % selected point incrementer (loop counter)
    for i=1:size(uda.xypts,3) % for each point
      if isnan(uda.xypts(fr,axn*2,i))==false && ...
          isnan(uda.xypts(fr+1,axn*2,i))==true
        spM(spInc,A)=i;
        x=round(uda.xypts(fr,axn*2-1,i));
        y=round(uda.xypts(fr,axn*2,i));
        % grab for comparison to the next frame;
        try
          RB(:,:,:,spInc,A)=imdat(y-psize:y+psize,x-psize:x+psize,:);
        catch
          RB(:,:,:,spInc,A)=NaN;
        end
        spInc=spInc+1;
      end
    end
  else % any other mode
    spM=sp;
    x=round(cp(1,1)); % get an integer X point
    y=round(cp(1,2)); % get an integer Y point
    % grab image region of interest for comparison to the next frame
    try
      RB=imdat(y-psize:y+psize,x-psize:x+psize,:);
    catch
      RB=NaN;
    end
  end
end

% check that we found some points to track
if isempty(find(spM>0,1))
  trackFailed=true;
end

% set videos frames to draw
uda.drawVid(AAxn(sum(spM,1)>0))=true;

% set number of unsuccessful tracks in each axis and point
failedFrames=zeros(size(spM));

% end of initialization

% main auto-tracking loop
while fr < frmax && trackFailed==false && get(h(35),'Value')~=1
  fr=fr+1; % increment the frame number by 1
  
  % track frames that fail to track in this round
  localFailedFrames=failedFrames*0; 

  % loop through each axis
  for A=1:numel(AAxn)
    axn=AAxn(A); % set the working axis

    % setup video stream and tag
    if axn>1
      offset=str2double(get(h(axn+13),'String')); % video stream offset
    else
      offset=0;
    end
    tag=get(h(axn+39),'Tag'); % tag holds the movie filename

    % load and process the next frame
    mov=mediaRead(tag,fr+offset,get(h(12),'Value'));
    imdat=mov.cdata(:,:,:);

    % for each point in the tracking set
    for S=1:numel(find(spM(:,A)>0));
      sp=spM(S,A); % selected point

      % in multi mode, don't overwrite existing data
      if atMode==5 && isnan(uda.xypts(fr,axn*2,sp))==false
        % do nothing - the point already exists
      else
        % extract roibase from the preloaded matrix
        roibase=squeeze(RB(:,:,:,S,A)); % S = selected point, A = axis

        % call the prediction function - it will use the other digitized
        % point locations to try and predict the location of the next point
        otherpts=uda.xypts(:,axn*2-1:axn*2,sp);
        [x,y,uda.predSeed]=AutoTrackPredictor(otherpts,fr-1,get(h(57), ...
          'Value'),uda.predSeed);

        % constrain x & y to fit within imdat
        if x>size(imdat,2) || x<1
          x=round(otherpts(fr-1,1));
        end
        if y>size(imdat,1) || y<1
          y=round(otherpts(fr-1,2));
        end

        % search for a matching image in the next frame using the
        % predicted x & y coordinates
        gammaS=get(h(13),'Value');
        try
          [xnew,ynew,fitt]=regionID4(double(roibase),[x,y], ...
            double(imdat),gammaS,h);
        catch
          fitt=-1;
          xnew=NaN;
          ynew=NaN;
        end
        cp=[xnew,ynew]; % update currentpoint

        % Search for a marker centroid (if desired & possible)
        findCent=get(h(55),'Value'); % check the UI for permission
        if isnan(cp(1))==0 && findCent==1
          [cp]=click2centroid(h,cp,axn,imdat);
        end

        % update uda.xypts
        uda.xypts(fr,axn*2-1,sp)=cp(1,1); % set x point
        uda.xypts(fr,axn*2,sp)=cp(1,2); % set y point
        uda.offset(fr,axn)=offset; % set offset
        intData.fitt(sp,axn)=fitt; % keep fitt for later decision-making

        % post-matching decision making
        if fitt < thold || isnan(fitt)
          failedFrames(S,A)=failedFrames(S,A)+1;
          localFailedFrames(S,A)=1;
          uda.drawVid(:)=true;
          uda.xypts(fr,axn*2-1,sp)=NaN; % set x point
          uda.xypts(fr,axn*2,sp)=NaN; % set y point
          spReturn=sp; % set return point to the one that failed
          axnReturn=axn; % set return axis
        else
          % Shift the image display area to follow the point if we've
          % tracked it out of the screen
          axisdata=get(uda.handles(axn+39));
          % X axis
          if cp(1)>axisdata.XLim(2)     % right of current xlim
            delta=cp(1)-axisdata.XLim(2)+10;
            axisdata.XLim(2)=axisdata.XLim(2)+delta;
            axisdata.XLim(1)=axisdata.XLim(1)+delta;
            set(uda.handles(axn+39),'XLim',axisdata.XLim);
          elseif cp(1)<axisdata.XLim(1) % left of current xlim
            delta=cp(1)-axisdata.XLim(1)-10;
            axisdata.XLim(2)=axisdata.XLim(2)+delta;
            axisdata.XLim(1)=axisdata.XLim(1)+delta;
            set(uda.handles(axn+39),'XLim',axisdata.XLim);
          end
          % Y axis
          if cp(2)>axisdata.YLim(2)     % above of current ylim
            delta=cp(2)-axisdata.YLim(2)+10;
            axisdata.YLim(2)=axisdata.YLim(2)+delta;
            axisdata.YLim(1)=axisdata.YLim(1)+delta;
            set(uda.handles(axn+39),'YLim',axisdata.YLim);
          elseif cp(2)<axisdata.YLim(1) % below of current ylim
            delta=cp(2)-axisdata.YLim(1)-10;
            axisdata.YLim(1)=axisdata.YLim(1)+delta;
            axisdata.YLim(2)=axisdata.YLim(2)+delta;
            set(uda.handles(axn+39),'YLim',axisdata.YLim);
          end
        end % end of "if fitt" block
      end % end of multi-mode doesn't overwrite data "if" block

    end % end of points loop
  end % end of axes loop

  % strip any zeros from the intData.fitt matrix
  intData.fitt(intData.fitt==0)=NaN;

  % DLT update
  dltSet=unique(spM); 
  dltSet(dltSet<1)=[];
  for sp=dltSet'
    if sum(isnan(uda.xypts(fr,:,sp))-1)<=-4 && uda.dlt==1 % 2+ xy pts
      [xyz,res]=dlt_reconstruct(uda.dltcoef,uda.xypts(fr,:,sp)); % do DLT
      uda.dltpts(fr,1:3,sp)=xyz(1:3); % get the DLT points
      uda.dltres(fr,1,sp)=res; % get the DLT residual

      % check that we didn't exceed the DLT residual threshold
      if res > str2double(get(h(61),'String'))
        failedFrames(S,A)=failedFrames(S,A)+1;
        localFailedFrames(S,A)=1;
        uda.drawVid(:)=true;
        spReturn=sp; % set return point to the failed point
        sdx=find(intData.fitt(sp,:)==min(intData.fitt(sp,:)));
        axnReturn=sdx; % set return axis
        uda.xypts(fr,[sdx*2-1,sdx*2],sp)=NaN; % set xy points to NaN
        [xyz,res]=dlt_reconstruct(uda.dltcoef,uda.xypts(fr,:,sp)); %new DLT
        uda.dltpts(fr,1:3,sp)=xyz(1:3); % get the DLT points
        uda.dltres(fr,1,sp)=res; % get the DLT residual
      end

    else
      uda.dltpts(fr,1:3,sp)=NaN; % set DLT points to NaN
      uda.dltres(fr,1,sp)=NaN; % set DLT residuals to NaN
    end
  end

  % change current point if necessary
  set(h(32),'Value',spReturn);

  % set auto-tracker fit text
  try
    set(h(27),'String',...
      ['Autotrack fit: ',num2str(intData.fitt(spReturn,axnReturn))]);
  catch
  end

  % advance a frame and redraw the screen
  set(h(5),'Value',fr);
  DLTdv3(1,uda); % call self for video refresh

  if atMode==3 || (atMode==5 && keyadvance==1)
    if keyadvance==0 %click advance in semiauto mode
      quickRedraw(uda,h,sp,fr);
      updateSmallPlot(h,axn,cp);
    else % advance via 'f' key
      % do nothing
    end
    return % semi-auto mode returns after one pass
  else
    % do nothing
  end
  
  % check failure states
  if max(max(failedFrames))>uda.gapJump
    trackFailed=true;
  end
  
  % reset failedFrames to zero in cases where we acquired data
  failedFrames=failedFrames.*localFailedFrames;

  pause(.01); % let MATLAB draw the figure
end % end of main auto-track "while" loop

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% regionID4

function [x,y,fit]=regionID4(prevRegion,prevXY,newData,gammaS,h)

% function [x,y,fit]=regionID4(prevRegion,prevXY,newData,gammaS,h)
%
% A cross-correlation based generalized image tracking program.
%
% Version history:
% 1.0 - Ty Hedrick, 3/5/2002 - initial release version
% 2.0 - Ty Hedrick, 10/02/2002 - updated to use the 2d corr. coefficient
% 3.0 - Ty Hedrick, 07/13/2004 - updated to use fft based cross-correlation
% 4.0 - Ty Hedrick, 12/10/2005 - updated to scale the image data by the
% gamma value specified in the UI and used to display the images

% set some other preliminary variables
xy=prevXY; % base level xy
ssize=floor(size(prevRegion,1)/2); % search area deviation

% grab a block of data from the newData image
try
  chunk=newData(xy(2)-ssize:xy(2)+ssize,xy(1)-ssize:xy(1)+ssize,:);
catch
  chunk=ones(ssize*2+1,ssize*2+1)*NaN;
end

% apply gamma and rescale (grayscale only)
if get(h(12),'Value')==false
  prevRegion=prevRegion(:,:,1).^gammaS;
  prevRegion=prevRegion-min(min(prevRegion));
  prevRegion=prevRegion*(1/max(max(prevRegion)));
  chunk=chunk(:,:,1).^gammaS;
  chunk=chunk-min(min(chunk));
  chunk=chunk*(1/max(max(chunk)+1));
end

% estimate new pixel positions with a 2D cross correlation.  For color
% video, pick the result with the best signal to noise ratio
xc=zeros(size(chunk,1)*2-1,size(chunk,2)*2-1,size(chunk,3));
I=zeros(size(chunk,3));
J=I;
fit=I;

for i=1:size(chunk,3)
  % detrend the chunk and prevRegion so they better fit the assumptions of
  % the cross-correlation
  chunk(:,:,i)=rot90(detrend(rot90(detrend(chunk(:,:,i)))),-1);
  prevRegion(:,:,i)=rot90(detrend(rot90(detrend(prevRegion(:,:,i)))),-1);

  % calculate the cross-correlation matrix of the chunk to the previous
  % region
  xc(:,:,i) = conv2(chunk(:,:,i), fliplr(flipud(prevRegion(:,:,i))));
  xc_s=xc(:,:,i);
  
  % get the location of the peak
  [I(i),J(i)]=find(xc_s==max(xc_s(:)));
  
  % do sub-pixel interpolation
  [I(i),J(i)] = subPixPos(xc_s,I(i),J(i));
  
  % give signal-to-noise ratio as fit
  fit(i)=max(xc_s(:))/(sum(abs(xc_s(:)))/numel(xc_s)+0.001);

  % set fit to -1 if it is a NaN
  if isnan(fit(i))==1
    fit(i)=-1;
  end
end

% place in world coordinates
x=xy(1)+J(fit==max(fit))-ssize*2-1;
y=xy(2)+I(fit==max(fit))-ssize*2-1;

% single number fit for export
fit=max(fit);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% subPixPos

function [x,y] = subPixPos(c,pi,pj)

% function [x,y] = subPixPos(c,pi,pj)
%
% Uses Matlab's 2D interpolation fuction to estimate a sub-pixel location
% of the peak in array c near pi,pj

% check to see that c is large enough for interpolation
if sum(size(c)<5)>0
  x=pi;
  y=pj;
  return
end

% subsample c near the peak
c2=c(pi-2:pi+2,pj-2:pj+2);

% interpolate
[xs,ys]=meshgrid(1:5,1:5);
[xm,ym]=meshgrid(1:.01:5,1:.01:5);
xc2=interp2(xs,ys,c2,xm,ym,'spline');

% find new peak
[i2,j2]=find(xc2==max(xc2(:)));

% convert back to pixel coordinates
x=xm(1,i2)-3+pi;
y=ym(j2,1)-3+pj;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% AutoTrackPredictor

function [x,y,predSeed]=AutoTrackPredictor(otherpts,fr,mode,predSeed)

% function [x,y,predSeed]=AutoTrackPredictor(otherpts,fr,mode,predSeed)
%
% This function attempts to predict the [x,y] coordinates of the point in
% frame fr+1 based on it's location at other times.  The predictor
% algorithm is specified by the "Autotrack predictor" menu entry, with a
% few caveats as to the amount of prior data required for the different
% algorithms.  The selected menu entry number is passed in as "mode" from
% the calling function.
%
% Modes are:
% 1: extended Kalman (best predictor)
% 2: double expondential (better in some circumstances)
% 3: linear fit (okay predictor)
% 4: static (special case)

% get the amount of data available for prediction
if fr<11
  %ndpts=sum(1-isnan(otherpts(1:fr,1)));
  ndpts=find(isnan(otherpts(1:fr,1))==false);
else
  %ndpts=sum(1-isnan(otherpts(fr-10:fr,1)));
  ndpts=find(isnan(otherpts(fr-10:fr,1))==false)+fr-11;
end

% if we have little data, force certain algorithms
if numel(ndpts)<3
  forceMode=4; % static
elseif numel(ndpts)<8 || fr < 11
  forceMode=3; % linear
else
  forceMode=0; % any
end

% choose a mode based on the menu and data
mode=max([mode,forceMode]);

% make a prediction
if mode==4 % static
  x=round(otherpts(ndpts(end),1));
  y=round(otherpts(ndpts(end),2));
elseif mode==3 % linear fit
  prevpts=otherpts(ndpts(end-2:end),:);
  seq=(1:size(prevpts,1))';
  p=polyfit(seq,prevpts(:,1),1);
  x=round(polyval(p,4));
  p=polyfit(seq,prevpts(:,2),1);
  y=round(polyval(p,4));
elseif mode==1 % extended Kalman
  kpts=otherpts(fr-10:fr,:);
  [p]=kalmanPredictorAcc(kpts);
  p=round(p);
  x=p(1);
  y=p(2);
elseif mode==2 % double exponential
  kpts=otherpts(fr-10:fr,:);
  [p,predSeed.alpha]=doubleExpPredictor(kpts(:,1),predSeed.alpha);
  x=round(p);
  [p,predSeed.alpha]=doubleExpPredictor(kpts(:,2),predSeed.alpha);
  y=round(p);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% dlt_inverse

function [uv] = dlt_inverse(c,xyz)

% function [uv] = dlt_inverse(c,xyz)
%
% This function reconstructs the pixel coordinates of a 3D coordinate as
% seen by the camera specificed by DLT coefficients c
%
% Inputs:
%  c - 11 DLT coefficients for the camera, [11,1] array
%  xyz - [x,y,z] coordinates over f frames,[f,3] array
%
% Outputs:
%  uv - pixel coordinates in each frame, [f,2] array
%
% Ty Hedrick

% write the matrix solution out longhand for Matlab vector operation over
% all points at once
uv(:,1)=(xyz(:,1).*c(1)+xyz(:,2).*c(2)+xyz(:,3).*c(3)+c(4))./ ...
  (xyz(:,1).*c(9)+xyz(:,2).*c(10)+xyz(:,3).*c(11)+1);
uv(:,2)=(xyz(:,1).*c(5)+xyz(:,2).*c(6)+xyz(:,3).*c(7)+c(8))./ ...
  (xyz(:,1).*c(9)+xyz(:,2).*c(10)+xyz(:,3).*c(11)+1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% dlt_reconstruct

function [xyz,rmse] = dlt_reconstruct(c,camPts)

% function [xyz,rmse] = dlt_reconstruct(c,camPts)
%
% This function reconstructs the 3D position of a coordinate based on a set
% of DLT coefficients and [u,v] pixel coordinates from 2 or more cameras
%
% Inputs:
%  c - 11 DLT coefficients for all n cameras, [11,n] array
%  camPts - [u,v] pixel coordinates from all n cameras over f frames,
%   [f,2*n] array
%
% Outputs:
%  xyz - the xyz location in each frame, an [f,3] array
%  rmse - the root mean square error for each xyz point, and [f,1] array,
%   units are [u,v] i.e. camera coordinates or pixels
%
% Ty Hedrick

% number of frames
nFrames=size(camPts,1);

% number of cameras
nCams=size(camPts,2)/2;

% setup output variables
xyz(1:nFrames,1:3)=NaN;
rmse(1:nFrames,1)=NaN;

% process each frame
for i=1:nFrames

  % get a list of cameras with non-NaN [u,v]
  cdx=find(isnan(camPts(i,1:2:nCams*2))==false);

  % if we have 2+ cameras, begin reconstructing
  if numel(cdx)>=2

    % initialize least-square solution matrices
    m1=[];
    m2=[];

    m1(1:2:numel(cdx)*2,1)=camPts(i,cdx*2-1).*c(9,cdx)-c(1,cdx);
    m1(1:2:numel(cdx)*2,2)=camPts(i,cdx*2-1).*c(10,cdx)-c(2,cdx);
    m1(1:2:numel(cdx)*2,3)=camPts(i,cdx*2-1).*c(11,cdx)-c(3,cdx);
    m1(2:2:numel(cdx)*2,1)=camPts(i,cdx*2).*c(9,cdx)-c(5,cdx);
    m1(2:2:numel(cdx)*2,2)=camPts(i,cdx*2).*c(10,cdx)-c(6,cdx);
    m1(2:2:numel(cdx)*2,3)=camPts(i,cdx*2).*c(11,cdx)-c(7,cdx);

    m2(1:2:numel(cdx)*2,1)=c(4,cdx)-camPts(i,cdx*2-1);
    m2(2:2:numel(cdx)*2,1)=c(8,cdx)-camPts(i,cdx*2);

    % get the least squares solution to the reconstruction
    xyz(i,1:3)=linsolve(m1,m2);

    % compute ideal [u,v] for each camera
    uv=m1*xyz(i,1:3)';

    % compute the number of degrees of freedom in the reconstruction
    dof=numel(m2)-3;

    % estimate the root mean square reconstruction error
    rmse(i,1)=(sum((m2-uv).^2)/dof)^0.5;
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% quickRedraw

function quickRedraw(uda,h,sp,fr)

% function quickRedraw(uda,h,sp,fr)
%
% Draws graphical (non-image) elements on the video panels - much quicker
% than refreshing the image and graphical elements together.

% loop through each axes and update it
for i=1:uda.nvid

  % make the axis of interest active
  set(h(2),'CurrentAxes',h(i+39));
  xl=xlim;

  % get the kids & delete everything but the image
  kids=get(h(i+39),'Children');
  if length(kids)>1
    delete(kids(1:end-1)); % assume the bottom of the stack is the image
  end

  % plot any XY points (selected point)
  if isnan(uda.xypts(fr,i*2,sp))==0
    plot(h(i+39),uda.xypts(fr,(i)*2-1,sp),uda.xypts(fr,i*2,sp),'ro', ...
      'HitTest','off');
  end

  % get the user settings for plotting the extended DLT information
  dltvf=get(h(53),'Value');

  % plot any DLT points (selected point) if desired
  if isnan(uda.dltpts(fr,1,sp))==0 && dltvf==1
    xy=dlt_inverse(uda.dltcoef(:,i),uda.dltpts(fr,:,sp));
    plot(h(i+39),xy(1),xy(2),'gd','HitTest','off');
  end

  % if no XY points & no DLT points plot partialDLT line if possible
  % & desired
  if isnan(uda.xypts(fr,i*2,sp)) && isnan(uda.dltpts(fr,1,sp)) ...
      && sum(isnan(uda.xypts(fr,:,sp))-1)==-2 && uda.dlt==1 && dltvf==1

    idx=find(isnan(uda.xypts(fr,:,sp))==0);
    dltcoef1=uda.dltcoef(:,idx(2)/2);
    dltcoef2=uda.dltcoef(:,i);
    u=uda.xypts(fr,idx(1),sp);
    v=uda.xypts(fr,idx(2),sp);
    [m,b]=partialdlt(u,v,dltcoef1,dltcoef2);
    xpts=xl';
    ypts=m.*xpts+b;
    plot(h(i+39),xpts,ypts,'b-','HitTest','off');
  end

  % plot non-selected points
  if uda.numpts>1
    ptarray=1:uda.numpts; % array of all the points
    ptarray(sp)=[]; % remove the selected point
    % XY
    xyPts=shiftdim(uda.xypts(fr,i*2-1:i*2,ptarray))';
    xyPts(isnan(xyPts(:,1)),:)=[];
    plot(h(i+39),xyPts(:,1),xyPts(:,2),'co','HitTest','off');

    % XYZ
    if uda.dlt
      xyzPts=shiftdim(uda.dltpts(fr,:,ptarray))';
      xyzPts(isnan(xyzPts(:,1)),:)=[];
      xyPts=dlt_inverse(uda.dltcoef(:,i),xyzPts);
      plot(h(i+39),xyPts(:,1),xyPts(:,2),'cd','HitTest','off');
    end
  end
end % end for loop through the video axes

% update the string fields in the GUI
DLTdv3(4,uda);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% dlt_confidenceIntervals

function [CI,tol,weights]=dlt_confidenceIntervals(coefs,camPts,minErr)

% function [CI,tol,weights]=dlt_confidenceIntervals(coefs,camPts,minErr)
%
% A tool for creating 95% confidence intervals for digitized points along
% with tolerance and weight matrices for use with spline filtering tools.
% Uses bootstrapping and may
%
% Inputs:
%  coefs - the DLT coefficients for the cameras
%  camPts - the XY coordinates of the digitized points
%
% Outputs:
%  CI - the 95% confidence interval values for the digitized points - i.e.
%   the xyz coordinates have a 95% confidence interval of xyz+CI to xyz-CI
%  tol - tolerance information for use with a smoothing spline
%  weights - weight information for use with a smoothing spline
%
% Ty Hedrick

% set a minimum error of zero if none is specified
if exist('minErr','var')==false
  minErr=0;
end

% number of cameras
nCams=size(coefs,2);

% number of points
nPts=size(camPts,2)./(2*size(coefs,2));

% number of bootstrap iterations
bsIter=50;

% create a progress bar
h=waitbar(0,'Creating 95% confidence intervals...');

% loop through each individual point
xyzBS(1:size(camPts,1),1:3,1:bsIter)=NaN;
xyzSD(1:size(camPts,1),1:nPts*3)=NaN;
for i=1:nPts
  % reconstruct based on the xy points and the coefficients
  icamPts=camPts(:,i*2*nCams-2*nCams+1:i*2*nCams);
  [xyz,rmse] = dlt_reconstruct(coefs,icamPts);
  
  % enforce minimum error
  rmse(rmse<minErr)=minErr;

  % don't trust rmse values from only two cameras; instead replace them
  % with the average for all two-camera situations
  nanSums=sum(abs(1-isnan(icamPts(:,2:2:nCams*2))),2);
  mnRmse=mean(rmse(nanSums==2));
  rmse(nanSums==2)=mnRmse;

  % bootstrap loop
  xyzBS(1:size(xyz,1),1:3,1:bsIter)=NaN;
  for j=1:bsIter
    per=randn(size(icamPts)).*repmat(rmse,1,2*nCams)+icamPts;
    [xyzBS(:,:,j)] = dlt_reconstruct(coefs,per);
    waitbar(j*i/(nPts*bsIter),h);
  end

  for j=1:size(xyz,1)
    xyzSD(j,i*3-2:i*3)=inanstd(rot90(squeeze(xyzBS(j,:,:))));
  end

end

% build confidence intervals
CI=1.96*xyzSD;

% build spline filtering weights
weights=(1./(xyzSD./repmat(min(xyzSD),size(xyzSD,1),1)));

% export tolerances for spline filtering
tol=inansum(weights.*(xyzSD.^2));

% clean up the progress bar
close(h)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% dlt_splineFilter

function [Ddata]=dlt_splineFilter(data,tol,weights,order)

% function [Ddata]=dlt_splineFilter(data,tol,weights,order)
%
% Inputs:
%   data - a columnwise data matrix. No NaNs or Infs please.
%   tol - the total error allowed: tol=sum((data-Ddata)^2)
%   weights - weighting function for the error:
%     tol=sum(weights*(data-Ddata)^2)
%   order - the derivative order (note that tol is with respect to the 0th
%     derivative)
%
% Outputs:
%   Ddata - the smoothed function (or its derivative) evaluated across the
%     input data
%
% Uses the spaps function of the spline toolbox to compute the smoothest
% function that conforms to the given tolerance and error weights.
%
% version 2, Ty Hedrick, Feb. 28, 2007

% create a sequence matrix, assume regularly spaced data points
X=(1:size(data,1))';

% set any NaNs in the weight matrix to zero
weights(isnan(weights))=0;

% spline order
sporder=3; % quintic spline, okay for up to 3rd order derivative

% spaps can't handle a weights matrix instead of a weights vector, so we
% loop through each column in data ...
Ddata=data*NaN;
for i=1:size(data,2)
  
  % Non-NaN index
  idx=find(isnan(data(:,i))==false);

  if numel(idx)>3
    [sp] = spaps(X(idx),data(idx,i)',tol(i),weights(idx,i),sporder);

    % get the derivative of the spline
    spD = fnder(sp,order);

    % compute the derivative values on X
    Ddata(idx,i) = fnval(spD,X(idx));
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% dlt_splineInterp

function [out,fitted]=dlt_splineInterp(in,type)

% function [out,fitted]=dlt_splineInterp(in,'type')
% Description: 	Fills in NaN points with the result of a cubic spline 
%	       	interpolation.  Marks fitted points with a '1' in a new,
%	       	final column for identification as false points later on.
%	       	This function is intended to work with 3-D points output
%	       	from the 'reconfu' Kinemat function.  Points marked with
%					a '2' were not fitted because of a lack of data
%	
%					'type' should be either 'nearest','linear','cubic' or 'spline'
%
%					Note: the 'fitted' return variable is only 1 column no matter
%					how many columns are passed in 'in', 'fitted' reflects _any_
%					fits performed on that row in any column of 'in'
%
% Ty Hedrick

fitted(1:size(in,1),1)=0; % initialize the fitted output matrix

for k=1:size(in,2) % for each column
	Y=in(:,k); % the Y (function resultant) value is the column of interest
	X=(1:1:size(Y,1))'; % X is a linear sequence of the same length as Y

	Xi=X; Yi=Y; % duplicate X and Y and use the duplicates to mess with

	nandex=find(isnan(Y)==1); % get an index of all the NaN values
	fitted(nandex,1)=1; % set the fitted matrix based on the known NaNs

	Xi(nandex,:)=[]; % delete all NaN rows from the interpolation matrices
	Yi(nandex,:)=[]; 

	if size(Xi,1)>=1 % check that we're not dealing with all NaNs
		Ynew=interp1(Xi,Yi,nandex,type,'extrap'); % interpolate new Y values
		in(nandex,k)=Ynew; % set the new Y values in the matrix
		if sum(isnan(Ynew))>0
			disp('dlt_splineInterp: Interpolation error, try the linear option')
			break
		end
	else
		% only NaNs, don't interpolate
	end

end

out=in; % set output variable

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% chex

function [I] = chex(n,p,q)

% draw a checkerboard

bs = zeros(n);
ws = ones(n);
twobytwo = [bs ws; ws bs];
I = repmat(twobytwo,p,q);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% kalmanPredictorAcc

function [p,filtSys] = kalmanPredictorAcc(seq)

% function [p,filtSys] = kalmanPredictorAcc(seq)
%
% A multi-dimensional, velocity-based Kalman predictor
%
% Inputs: seq - a (:,n) columnwise matrix with n independent series of data
%   points sampled at a constant time step
%
% Outputs: p - a (1,n) vector of the predicted value(s) of seq in the next
%   time step
%
% Thanks for guidance in:
% The Kalman Filter toolbox by Kevin Murphy, available at:
% http://www.cs.ubc.ca/~murphyk/Software/index.html
%
% and also to the Kalman filter info at:
% http://www.cs.unc.edu/~welch/kalman/
%
% Ty Hedrick: Jan 27, 2007

% remove NaNs by spline interpolation
seq=dlt_splineInterp(seq,'spline');
seq(isnan(sum(seq,2))==true,:)=[];

% check data size & exit if inappropriate
if size(seq,1)<4
  p=seq(end,:); % give a reasonable p
  filtSys=seq; % return the unfiltered system
  return
end

% start setting up the Kalman predictor
nd = size(seq,2); % number of data columns
ss = nd*3; % system size (position, velocity & acc for each data column)

% build a system matrix of the appropriate size - because we're probably
% dealing with the x,y projection of x,y,z motion we can't construct a real
% system description.  However, the description below does a reasonable job
% for most 2D-projection tracking cases.
A=zeros(ss);
for i=1:nd
  A(i,i)=1;
  A(i,i+nd)=0; 
  A(i+nd,i+nd)=1;
  A(i,i+nd*2)=2;
  A(i+nd*2,i+nd*2)=1;
  A(i+nd,i+nd*2)=1;
end

% build an observation matrix of the appropriate size
O=zeros(nd,ss);
for i=1:nd
  O(i,i)=1;
end

% build the system error covariance matrix
Q=1*eye(ss);

% build the data error covariance matrix
R=.1*eye(nd);

% initial system state
initSys=[seq(1,:),diff(seq(1:2,:),1),diff(diff(seq(1:3,:),1))];

% initial system covariance
initCov=0.01*eye(ss);

% use the Kalman filter to track the system state
[filtSys]=kFilt(seq,A,O,Q,R,initSys,initCov);

% create a prediction from the final system state
predSys = (A*(filtSys(end,:)'))';
p=predSys(1:nd);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% kFilt

function [filtSys] = kFilt(seq,A,O,Q,R,initSys,initCov)

% [filtSys] = kFilt(seq,A,O,Q,R,initSys,initCov)
%
% Inputs:
% seq(:,t) - the observed data at time t
% A - the system matrix
% O - the observation matrix
% Q - the system covariance
% R - the observation covariance
% initSys - the initial state vector
% initCov - the initial state covariance
%
% Outputs:
% filtSys - the estimation of the system state

[N,nd] = size(seq); % # of data points and number of data streams
ss = nd*3; % system size [again assuming position, velocity, acc]

% initalize output
filtSys = zeros(N,ss); % filtered system

% walk through the data, updating the filter as we go
%
% set initial values before the loop
predSys = initSys;
predCov = initCov;
for i=1:N

  e = seq(i,:) - (O*(predSys'))'; % error

  S = O*predCov*O' + R;
  Sinv = inv(S);

  K = predCov*O'*Sinv; % Kalman gain matrix

  prevSys = predSys + (K*(e'))'; % a oosteriori prediction of system state
  prevCov = (eye(ss) - K*O)*predCov; % a posteriori covariance

  predSys = (A*(prevSys'))'; % predict next system state
  predCov = A*prevCov*A' + Q; % predict next system covariance

  filtSys(i,:)=prevSys; % store the a posteriori prediction
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% doubleExpPredictor

function [p,alpha] = doubleExpPredictor(seq,alphaInit)

% function [p,alpha] = doubleExpPredictor(seq,alphaInit)
%
% Implements a double exponential predictor function, finds best fit
% coefficients usings the Matlab simplex implementation (fminsearch).
%
% Inputs: seq - the point sequence
%  alphaInit - the starting point for exponential optimization (optional)
%
% Outputs: p - the predicted next point in the sequence
%  alpha - the exponent used to get the prediction
%
% Ty Hedrick, Jan 27, 2007

% set default value for alpha if it isn't available
if exist('alphaInit','var')~=1
  alphaInit=0.5;
end

anonFunc=@expScore;
[alpha]=fminsearch(anonFunc,alphaInit,[],seq);

[mse,out,p]=expScore(alpha,seq);

% prediction of the next point is the last entry in p
p=p(end,:);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% expScore

function [mse,out,p]=expScore(alpha,seq)

% scoring function for the minimizer used in the doubleExpPredictor

a=alpha(1);
b=alpha(1);

% two parameter
out(1,1)=NaN; % St(1)
out(1,2)=NaN; % Bt(1)
out(2,1)=seq(1,1); % St(2)
out(2,2)=seq(1,1)+(seq(2,1)-seq(1,1)); % Bt(2)
p(1:3,1)=NaN;

for i=3:size(seq,1)
  out(i,1)=a*seq(i,1)+(1-a)*out(i-1,1);
  out(i,2)=b*out(i,1)+(1-b)*out(i-1,2);
  p(i+1,1)=(2+a/(1-a))*out(i,1)-(1+b/(1-b))*out(i,2);
end

% calculate mean square error of the prediction
mse=inanmean((seq(:,1)-p(1:end-1,1)).^2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% mediaInfo

function [info]=mediaInfo(fname)

% function [info]=mediaInfo(fname);
%
% Wrapper which uses aviinfo or cineInfo depending on which is appropriate.

if strcmpi(fname(end-3:end),'.avi')
  info=aviinfo(fname);
elseif strcmpi(fname(end-3:end),'.cin')
  info=cineInfo(fname);
elseif strcmpi(fname(end-4:end),'.cine')
  info=cineInfo(fname);
else
  info=[];
  disp('mediaInfo: bad file extension')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% mediaRead

function [mov]=mediaRead(fname,frame,incolor)

% function [mov]=mediaRead(fname,frame,incolor);
%
% Wrapper function which uses aviread or cineRead depending on what type of
% file is detected.  Also performs the flipud() on the result of aviread
% and puts the cdata result from cineRead into a mov.* structure.

if strcmpi(fname(end-3:end),'.avi')
  mov=aviread(fname,frame);
  if incolor==false
    mov.cdata=flipud(mov.cdata(:,:,1));
  else
    for i=1:size(mov.cdata,3)
      mov.cdata(:,:,i)=flipud(mov.cdata(:,:,i));
    end
  end
elseif strcmpi(fname(end-3:end),'.cin')
  mov.cdata=cineRead(fname,frame);
elseif strcmpi(fname(end-4:end),'.cine')
  mov.cdata=cineRead(fname,frame);
else
  mov=[];
  disp('mediaRead: bad file extension')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% cineRead
function [cdata] = cineRead(fileName,frameNum)

% function [cdata] = cineRead(fileName,frameNum)
%
% Reads the frame specified by frameNum from the Phantom camera cine file
% specified by fileName.  It will not read compressed cines.  Furthermore, 
% the bitmap in cdata may need to be flipped, transposed or rotated to 
% display properly in your imaging application.
%
% frameNum is 1-based and starts from the first frame available in the
% file.  It does not use the internal frame numbering of the cine itself.
%
% This is a pure Matlab implementation that has been tested on grayscale 
% CIN files from a Phantom v5.1 and Phantom v7.0 camera.
%
% Ty Hedrick, April 27, 2007
%   updated November 06, 2007

% check inputs & proceed
if strcmpi(fileName(end-3:end),'.cin') || ...
    strcmpi(fileName(end-4:end),'.cine') && isnan(frameNum)==false

  % get file info from the cineInfo function
  info=cineInfo(fileName);

  % pad is the gap between the start of the file and the location of the
  % first frame
  pad=info.startPad+(20+info.xtraPad)*info.NumFrames;

  % offset is the location of the start of the target frame in the file -
  % the pad + 8bits for each frame + the size of all the prior frames
  offset=5800+pad+8*frameNum+(frameNum-1)* ...
    (info.Height*info.Width*info.bitDepth/8);

  % get a handle to the file from the filename
  f1=fopen(fileName);

  % seek ahead from the start of the file to the offset (the beginning of
  % the target frame)
  fseek(f1,offset,-1);

  % read a certain amount of data in - the amount determined by the size
  % of the frames and the camera bit depth, then cast the data to either
  % 8bit or 16bit unsigned integer
  if info.bitDepth==8
    cdata=fread(f1,info.Height*info.Width,'*uint8');
  else
    cdata=fread(f1,info.Height*info.Width,'*uint16');
  end

  % destroy the handle to the file
  fclose(f1);

  % the data come in from fread() as a 1 dimensional array; here we
  % reshape them to a 2-dimensional array of the appropriate size
  cdata=reshape(cdata,info.Width,info.Height);
  cdata=fliplr(rot90(cdata,-1));

else
  % complain if the use gave what appears to be an incorrect filename
  disp(sprintf( ...
    '%s does not appear to be a cine file or frameNum is not available.'...
    ,fileName))
  cdata=NaN;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% cineInfo
function [info] = cineInfo(fileName)

% function [info] = cineInfo(fileName)
%
% Reads header information from a Phantom Camera cine file, analagous to
% Mathworks aviinfo().  The values returned are:
%
% info.Width - image width
% info.Height - image height
% info.startFrame - first frame # saved from the camera cine sequence
% info.endFrame - last frame # saved from the camera cine sequence
% info.bitDepth - image bit depth
% info.frameRate - frame rate the cine was recorded at
% info.exposure - frame exposure time in microseconds
% info.NumFrames - total number of frames
%
% Ty Hedrick, April 27, 2007
%  updated November 6, 2007

% check for cin suffix.  This program will produce erratic results if run
% on an AVI!
if strcmpi(fileName(end-3:end),'.cin') || ...
    strcmpi(fileName(end-4:end),'.cine')

  % read the first chunk of header
  %
  % get a file handle from the filename
  f1=fopen(fileName);

  % read the 1st 410 32bit ints from the file
  header32=double(fread(f1,410,'*int32'));

  % release the file handle
  fclose(f1);

  % set output values from certain magic locations in the header
  info.Width=header32(13);
  info.Height=header32(14);
  info.startFrame=header32(5);
  info.NumFrames=header32(6);
  info.endFrame=info.startFrame+info.NumFrames-1;
  info.bitDepth=header32(17)/(info.Width*info.Height/8);
  info.frameRate=header32(214);
  info.exposure=header32(215);
  info.cameraType=header32(220);
  info.softwareVersion=header32(222);
  info.xtraPad=header32(410); % extra per-frame padding bytes
  
  % deal with raw file format change after version 649
  if info.softwareVersion>649 && info.bitDepth>8
    info.startPad=16;
  else
    info.startPad=0;
  end

else
  disp(sprintf('%s does not appear to be a cine file.',fileName))
  info=[];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% inanstd
function [Y] = inanstd(varargin)

% uses the nanstd function if available, otherwise mimics it with some
% slightly slower code
if exist('nanstd','file')==2
  Y=nanstd(varargin{:});
else
  if nargin==1
    m=varargin{1};
    Y(1:size(m,2),1)=NaN;
    for i=1:size(m,2)
      Y(i,1)=std(m(isnan(m(:,i))==false,i));
    end
  else
    Y=NaN;
    disp(['nanstd with more than one argument is not supported', ...
      'on this computer'])
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% inanmean
function [y] = inanmean(x,dim)

% internal version of nanmean in case the user doesn't have the stats
% toolbox

if nargin==1
  dim=1;
end

ndx=isnan(x);
x(ndx)=0; % turn NaNs to zeros

nn=sum(~ndx,dim); % # of non-NaN values
nn(nn==0)=NaN; % don't allow zeros

% add it up
s=sum(x(~ndx),dim);

% get the mean
y=s./nn;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% inansum

function [y] = inansum(x,dim)

% internal version of nansum in case the user doesn't have the stats
% toolbox

if nargin==1
  dim=1;
end

% set NaNs to zero and sum
x(isnan(x))=0;
y=sum(x,dim);

