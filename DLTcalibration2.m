function [] = DLTcalibration2(varargin)

% function [] = DLTcalibration2()
%
% DLTcalibration2 is a tool for digitizing Direct Linear Transformation
% calibration images and computing the DLT coefficients using either
% standard DLT or modified DLT then examining the results for erroneous,
% badly defined or badly digitized points.
%
% Ty Hedrick 8/3/04

if prod(size(varargin))==0 % no input arguments, start the program and draw the gui
  disp('DLTcalibration2: prerelease 9/25/2005')

  h(1)=figure('Menubar','none','Doublebuffer','on','NumberTitle','off', ...
    'Resize','off','Name','DLTcalibration2 controls','Units', ...
    'characters','Position', [1 20 56 16]); % create a new figure

  h(2)=uicontrol('Style','pushbutton','String','Load object coordinates','Units' ...
    ,'characters','Position',[1 13 30 2.5],'Callback', ...
    'DLTcalibration2(1)'); % Load coordinates pushbutton

  h(3)=uicontrol('Style','pushbutton','String','Load and digitize images','Units' ...
    ,'characters','Position',[1 10 30 2.5],'Callback', ...
    'DLTcalibration2(2)','enable','off'); % Load and digitize pushbutton

  h(4)=uicontrol('Style','pushbutton','String','Compute DLT coefficients','Units' ...
    ,'characters','Position',[1 7 30 2.5],'Callback', ...
    'DLTcalibration2(3)','enable','off'); % Compute coefficients pushbutton

  h(6)=uicontrol('Style','text','Units','characters','Position', ...
    [1 5 30 1.5],'String','DLT type:','HorizontalAlignment', ...
    'left','BackGroundColor',[.65 .8 1]); % DLT type label

  h(5)=uicontrol('Style','popup','Units','characters','Position', ...
    [1 2.5 30 2.5],'String','standard DLT|modified DLT ','Enable','off'); % DLT type menu

  h(7)=uicontrol('Style','text','Units','characters','Position', ...
    [33 3.5 22 3],'String','DLT average residual:','HorizontalAlignment', ...
    'left','BackGroundColor',[.65 .7 1]); % DLT residual text

  h(8)=uicontrol('Style','pushbutton','String','Quit','Units' ...
    ,'characters','Position',[33 13 22 2.5],'Callback', ...
    'close(gcf)','enable','on'); % quit pushbutton

  h(9)=uicontrol('Style','pushbutton','String','Help','Units' ...
    ,'characters','Position',[33 10 22 2.5],'Callback', ...
    'DLTcalibration2(0)','enable','on'); % help pushbutton

  h(10)=uicontrol('Style','pushbutton','String','DLT error analysis','Units' ...
    ,'characters','Position',[33 7 22 2.5],'Callback', ...
    'DLTcalibration2(4)','enable','off'); % DLT error analysis pushbutton

  h(11)=uicontrol('Style','pushbutton','String','Save data','Units' ...
    ,'characters','Position',[33 .5 22 2.5],'Callback', ...
    'DLTcalibration2(5)','enable','off'); % Save data pushbutton

  h(12)=uicontrol('Style','pushbutton','String','Calibrate another camera','Units' ...
    ,'characters','Position',[1 .5 30 2.5],'Callback', ...
    'DLTcalibration2(6)','enable','off'); % Save data pushbutton

  ud.handles=h; % simple userdata object
  ud.camnum=1; % additional common data

  for i=1:prod(size(h)) % for each handle set all handle info in
    set(h(i),'Userdata',ud); % userdata
  end
  
  return % exit the function after drawing the GUI

% back-end processing portions of the function
%
elseif prod(size(varargin))==1
  % assume a call but no data
  call=varargin{1};
  ud=get(gcbo,'Userdata'); % get simple userdata
  h=ud.handles; % get the handles
  uda=get(h(1),'Userdata'); % get complete userdata
elseif prod(size(varargin))==2
  call=varargin{1}; % put call in the expected variable
  uda=varargin{2}; % put userdata in the expected variable
  h=uda.handles; % put the GUI handles in the expected variable
else
  disp('DLTcalibration2: incorrect number of input arguments')
  return
end


% switchyard to handle updating & processing tasks for the figure
switch call
  case {0} % help button
		msg{1}='DLTcalibration2.m help';
		msg{2}='';
		msg{3}='The DLTcalibration2 program creates Direct Linear Transformation coefficients from a calibration object specification object and an image or series of images of that object.';
		msg{4}='';
		msg{5}='Usage:';
		msg{6}='Use the "Load object coordinates" button to select a calibration object specification file.  The file should be in comma separated value format with one header row and each subsequent row specifing the X,Y,Z coordinates of one location on the calibration object.';
		msg{7}='';
		msg{8}='Use the "Load and digitize images" button to start the digitizing program.  You must first specify the number of calibration points in each image, from 1 to the total # of calibration points.  If you enter less than the total number of calibration points, the program will expect to digitize multiple images.  The digitizing section itself features unlimited zoom in / zoom out, undo within an image and allows invisible or skipped points.  Follow the on-screen instructions.';
		msg{9}='';
		msg{10}='Use the "Compute DLT coefficients" button to calculate the coefficients from the digitized points and calibration object specification file.  Coefficients can either be computing using standard DLT (as implemented by Christoph Reinschmidt in dltfu.m) or modified DLT as implemented by Tomislav Pribanic in the mdlt1.m function).  The average DLT residual will be displayed in the text box to the right.';
		msg{11}='';
		msg{12}='The "DLT error analysis" button explores the effects of individually removing each of the digitized points from the coefficient calculation.  This should reveal any incorrectly digitized or specified points.';
		msg{13}='';
		msg{14}='The "Save data" button saves the DLT coefficients and digitized points to two separate comma separated value data files.';
		msg{15}='';
		msg{16}='Version 1.0, Ty Hedrick, August 4th, 2004';
		msg{17}='Thanks to Christoph Reinschmidt and Tomislav Pribanic for doing the hard work!';
		msgbox(msg,'DLTcalibration2.m Help');


  case {1} % load the calibration object specification
		[specfile,specpath]=uigetfile({'*.csv','comma separated values'}, ...
			'Please select your calibration object specification file');
		specdata=dlmread([specpath,specfile],',',1,0); % read in the calibration file
		if size(specdata,2)==3 % got a good spec file
			uda.specdata=specdata; % put it in userdata
			uda.specpath=specpath; % keep the path too

			% tell the user
			msg=sprintf('Loaded a %d point calibration object specification file.',size(specdata,1));
			msgbox(msg,'Success');
			% write back any modifications to the main figure userdata 
 			set(h(1),'Userdata',uda);
			% enable the next control
			set(h(3),'Enable','on');
      cd(specpath); % change to spec path directory
		else
			msg='The calibration object specification file must have 3 data columns. Aborting.';
			msgbox(msg,'Error','error');

			% make sure other controls are disabled
			set(h(3),'Enable','off');
			set(h(4),'Enable','off');
			set(h(10),'Enable','off');
			set(h(11),'Enable','off');
			return
		end
		
  case {2} % digitize calibration images

		% how many calibration points per image?
		prompt={'How many calibration points are in each image? '};
		def={sprintf('%d',size(uda.specdata,1))};
		dlgTitle='Preliminary info';
		answer=inputdlg(prompt,dlgTitle,1,def);

		ptsper=round(str2num(answer{1}));
    
    if mod(size(uda.specdata,1),ptsper)~=0
      msg=sprintf('The total number of points (%d) must be evenly divisible by the number of points per image.',size(uda.specdata,1));
      uiwait(msgbox(msg,'Error','error'));
      return
    end

		% get the image list
		if ptsper==size(uda.specdata,1) % one image
			[imfile,impath]=uigetfile({'*.tif';'*.jpg';'*.bmp';'*.avi'}, ...
				'Please select your calibration object image');
			uda.imfiles={imfile}; % copy results to userdata
			uda.impath=impath;
		else % multiple images
			[imfile,impath]=uigetfile({'*.tif';'*.jpg';'*.bmp';'*.avi'}, ...
				'Pick  one of the calibration images');
			prompt={'Add an * to select the appropriate image group'};
			def={imfile};
			dlgTitle='Calibration image filter';
			imfilefilt=inputdlg(prompt,dlgTitle,1,def);

			tempnames=dir(sprintf('%s%s%s',impath,filesep,imfilefilt{1})); % get file list
			for i=1:size(tempnames,1)
  			imfiles(i,1:size(tempnames(i,1).name,2))=tempnames(i,1).name;
			end
			filelist=sortrows(imfiles); % sort
			uda.imfiles=cellstr(filelist); % save to userdata as cell array
			uda.impath=impath; 

			if size(filelist,1)*ptsper==size(uda.specdata,1) % match?
				clear msg
				msg{1}='The files will be digitized in this order:';
				for i=1:size(filelist,1)
					msg{i+1}=uda.imfiles{i};
				end
				uiwait(msgbox(msg,'Success','modal'));
			else
				msg=sprintf('You specified %d images but needed %d.',size(filelist,1),size(uda.specdata,1)/ptsper);
				uiwait(msgbox(msg,'Error','error'));
				return
			end
		end

    % now start digitizing
    df=figure('Doublebuffer','on','Name','Digitizing window',...
      'NumberTitle','off','Menubar','none'); % digitizing figure

    gclabel=uicontrol('Style','text','Units','characters','Position', ...
      [.15 .25 20 1.5],'String','Gamma control:','HorizontalAlignment', ...
      'left','BackGroundColor',[.65 .8 1]); % gamma control label

    gcslider=uicontrol('Parent',df,'Units','characters',... % video gamma slider
      'Position',[23.15 .25 40 1.5],'String',{  'gamma' },...
      'Style','slider','Tag','slider1','Min',.1','Max',6,'Value',1,...
      'Enable','on', 'ToolTipString','Video Gamma slider');
		
		for i=1:prod(size(uda.imfiles)) % for each image
      % load image data from the movie or image file
      if strcmp('avi',lower(uda.imfiles{i}(end-2:end)))==1
        mov=aviread(sprintf('%s%s%s',uda.impath,filesep,uda.imfiles{i}));
        imdata=mov(1).cdata;
      else
        imdata=imread(sprintf('%s%s%s',uda.impath,filesep,uda.imfiles{i}));
      end
			ih=redlakeplot(flipud(imdata(:,:,1))); % plot it in the figure
      uda.imdata=get(ih,'Cdata'); % store the original image data
      uda.ih=ih; % stick the image handle in userdata
      uda.ia=get(ih,'Parent'); % image axis
      set(gcslider,'Callback','DLTcalibration2(7)'); % give the gamma slider a callback
      set(gcslider,'Userdata',uda); % set the slider user data
			title('click to set a point, space to set a null point, z to undo, =/- to zoom in/out, r to reset the zoom')
			set(gca,'XTickLabel','');
			set(gca,'YTickLabel','');
      
      axes(uda.ia); % make the image axis active
      
      % grab existing points for modification
      if uda.camnum>1
        pts=uda.pts;
      end
      
			j=1; % set the initial while loop condition
			while j<= ptsper % while we're still collecting points from the image
				rownum=(i-1)*ptsper+j; % overall point number
				xlabel(sprintf('%s: point #%d (overall point #%d)',uda.imfiles{i},j,rownum),'Interpreter','none'); % set the label
				[x,y,button]=ginput(1); % get a click
				
				% process clicks or button presses
				if button==1 % regular mouse click
					% record the points
					pts(rownum,2*uda.camnum-1)=x;
					pts(rownum,2*uda.camnum)=y;
					% plot the points
					ph(rownum,1)=plot(x,y,'ro','MarkerFaceColor','r');
					ph(rownum,2)=text(x+5,y+5,sprintf('%d,(%d)',j,rownum),'Color','r','FontSize',12);
					j=j+1; % increment j
					
				elseif button==122 & j>1 % undo
					pts(rownum-1,uda.camnum*2-1:uda.camnum*2)=NaN; % clear points
					eval('delete(ph(rownum-1,1));','') % delete the marker or fail gracefully
					eval('delete(ph(rownum-1,2));','') % delete the marker or fail gracefully
					j=j-1; % decrement j
				
				elseif button==32 % null point
					pts(rownum,uda.camnum*2-1:uda.camnum*2)=NaN; % set null point
					j=j+1; % increment j

				elseif button==61|45|114 % zoom
					pl=get(0,'PointerLocation'); % pointer location on the screen
					pos=get(df,'Position'); % get the figure position
					axh=uda.ia; % get handle to image axis
					axpos=get(axh,'Position'); % get axis position in figure
					% calculate pointer location in normalized units
    			plocal=[(pl(1)-pos(1,1))/pos(1,3), (pl(2)-pos(1,2))/pos(1,4)];
					xl=xlim;, yl=ylim; % x & y limits on axis
					% calculate the normalized position within the axis
        	plocal2=[(plocal(1)-axpos(1,1))/axpos(1,3) (plocal(2) ...
            -axpos(1,2))/axpos(1,4)];
					% calculate the actual pixel postion of the pointer
        	pixpos=round([(xl(2)-xl(1))*plocal2(1)+xl(1) ...
            (yl(2)-yl(1))*plocal2(2)+yl(1)]);
					% set the figure xlimit and ylimit
        	if button==61 % zoom in
          	xlim([pixpos(1)-(xl(2)-xl(1))/3 pixpos(1)+(xl(2)-xl(1))/3]);
          	ylim([pixpos(2)-(yl(2)-yl(1))/3 pixpos(2)+(yl(2)-yl(1))/3]);
        	elseif button==45 % zoom out
          	xlim([pixpos(1)-(xl(2)-xl(1))/1.5 pixpos(1)+(xl(2)-xl(1))/1.5]);
          	ylim([pixpos(2)-(yl(2)-yl(1))/1.5 pixpos(2)+(yl(2)-yl(1))/1.5]);
          elseif button==114
            xlim([0 size(imdata,2)])
            ylim([0 size(imdata,1)])
            axis equal
          end
				end % end button click processing
        
			end % end the while loop
			hold off % make sure the figure gets cleared between images
			plot(0,0);
		end % end the for loop
		
		uda.pts=pts; % copy data to the main structure

		% write back any modifications to the main figure userdata 
 		set(h(1),'Userdata',uda);

		close(df) % close the digitizing figure

		set(h(4),'Enable','on') % enable DLT compute button
		set(h(5),'Enable','on') % enable DLT type button

		msgbox('Digitizing complete.')
    
    
  case {3} % compute DLT coefficients
		% get the computation type from the menu

		if get(h(5),'Value')==1 % standard DLT
			set(gcf,'Pointer','watch')
			[uda.coefs(:,uda.camnum),uda.avgres(uda.camnum)]= ...
        dltfu(uda.specdata,uda.pts(:,uda.camnum*2-1:uda.camnum*2));
			set(gcf,'Pointer','arrow')
		else % modified DLT
			set(gcf,'Pointer','watch')
			[uda.coefs(:,uda.camnum),uda.avgres(uda.camnum)]= ...
        mdlt1(uda.specdata,uda.pts(:,uda.camnum*2-1:uda.camnum*2));
			set(gcf,'Pointer','arrow')
		end

		% update the user interface
		set(h(7),'String',sprintf('DLT average residual: %.5f',uda.avgres(uda.camnum)));
		
		% write back any modifications to the main figure userdata 
 		set(h(1),'Userdata',uda);

		set(h(10),'Enable','on'); % DLT error analysis button
		set(h(11),'Enable','on'); % Save data button
    set(h(12),'Enable','on'); % enable the "calibrate another camera" control
			
  case {4}	% DLT error analysis
		msg{1}='This function computes the DLT coefficients and residuals';
		msg{2}='with one of the calibration points removed.  Calibration';
		msg{3}='point # is shown on the X axis and DLT residual without that';
		msg{4}='point is on the Y axis.  A large drop in the residual';
		msg{5}='indicates that the calibration point in question may be';
		msg{6}='badly digitized or incorrectly specified in the calibration';
		msg{7}='object file.  This function does not modify any of the';
		msg{8}='existing calibration points, it only shows the outcome of';
		msg{9}='potential modifications.';

		uiwait(msgbox(msg,'Information','modal'));

		% start processing
		wh=waitbar(0,'Processing error values');
		for i=1:size(uda.specdata,1)
			waitbar(i/size(uda.pts,1)); % update waitbar size
			ptstemp=uda.pts(:,uda.camnum*2-1:uda.camnum*2);
			rescheck(i,1)=i; % build X axis column
			if isnan(ptstemp(i,1))==1 % no value anyway
				rescheck(i,2)=NaN; % no need to process
			else
				ptstemp(i,1:2)=NaN; % set to NaN and recalculate
				if get(h(5),'Value')==1 % standard DLT
					[coefs,rescheck(i,2)]=dltfu(uda.specdata,ptstemp);
				else % modified DLT
					[coefs,rescheck(i,2)]=mdlt1(uda.specdata,ptstemp);
				end
			end
		end
		close(wh)
		eah=figure;
		plot(rescheck(:,1),rescheck(:,2),'rd','MarkerFaceColor','r')
		ylabel('DLT residual with 1 calibration point removed')
		xlabel('Calibration point')
		

  case {5} % save data
		% use uiputfile to establish a filename for the coefficients
		[putname,putpath]=uiputfile(sprintf('%s/*.csv',uda.specpath), ...
			'DLT coefficients file','dltcoefs.csv');
			
		dlmwrite([putpath,putname],uda.coefs,',');
			
		% use uiputfile to establish a filename for the XY points
		[putname,putpath]=uiputfile(sprintf('%s/*.csv',putpath), ...
			'Calibration XY points file','xypoints.csv');
			
		dlmwrite([putpath,putname],uda.pts,',');
    msgbox('Data saved.');
    
  case {6} % calibrate another camera
    % shut off the calibration load button, loading a calibration frame
    % with a different number of points would cause lots of annoyance
    set(h(2),'enable','off');
    set(h(4),'enable','off'); % compute DLT coefficients
    set(h(10),'enable','off'); % DLT error analysis
    set(h(11),'enable','off'); % save data
    uda.camnum=uda.camnum+1;
    % write back any modifications to the main figure userdata 
 		set(h(1),'Userdata',uda);
    
    set(h(12),'enable','off'); % calibrate another camera
    
  case {7} % video gamma slider
    newimage=double(ud.imdata).^get(gcbo,'Value');
    newimage=newimage-min(min(newimage));
    newimage=newimage./max(max(newimage));
    newimage=uint8(newimage.*255);
    set(ud.ih,'Cdata',newimage);
    axes(ud.ia); % make the image axis active
    
    
end % end of switch / case statement


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% additional functions %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [han] = redlakeplot(varargin)

% function [han] = redlakeplot(rltiff,xy)
%
% Description:	Quick function to plot images from Redlake tiffs
% 	This function was formerly named birdplot
%
% Version history:
% 1.0 - Ty Hedrick 3/5/2002 - initial version

if nargin ~= 1 & nargin ~= 2
  disp('Incorrect number of inputs.')
  return
end

han=image(varargin{1},'CDataMapping','scaled');
set(han,'EraseMode','normal');
colormap(gray)
axis xy
hold on
axis equal

if nargin == 2
  plot([varargin{2}(:,1)],[varargin{2}(:,2)],'r.');
end


function [A,avgres,rawres] = dltfu(F,L,Cut)
% Description:	Program to calculate DLT coefficient for one camera
%               Note that at least 6 (valid) calibration points are needed
%               function [A,avgres] = dltfu(F,L,Cut)
% Input:	- F      matrix containing the global coordinates (X,Y,Z)
%                        of the calibration frame
%			 e.g.: [0 0 20;0 0 50;0 0 100;0 60 20 ...]
%		- L      matrix containing 2d coordinates of calibration 
%                        points seen in camera (same sequence as in F)
%                        e.g.: [1200 1040; 1200 1360; ...]
%               - Cut    points that are not visible in camera;
%                        not being used to calculate DLT coefficient
%                        e.g.: [1 7] -> calibration point 1 and 7 
%			 will be discarded.
%		      	 This input is optional (default Cut=[]) 
% Output:	- A      11 DLT coefficients
%               - avgres average residuals (measure for fit of dlt)
%			 given in units of camera coordinates
%
% Author:	Christoph Reinschmidt, HPL, The University of Calgary
% Date:		January, 1994
% Last changes: November 29, 1996
% 		July 7, 2000 - Ty Hedick - NaN points automatically
%                 added to cut.
%		August 8, 2000 - Ty Hedrick - added raw_res output
% Version:	1.1
% References:	Woltring and Huiskes (1990) Stereophotogrammetry. In
%               Biomechanics of Human Movement (Edited by Berme and
%               Cappozzo). pp. 108-127.

if nargin==2; Cut=[]; end;

if size(F,1) ~= size(L,1)
disp('# of calibration points entered and seen in camera do not agree'), return
end

% find the NaN points and add them to the cut matrix
for i=1:size(L,1)
  if isnan(L(i,1))==1
    Cut(1,size(Cut,2)+1)=i;
  end
end

m=size(F,1); Lt=L'; C=Lt(:);

for i=1:m
  B(2*i-1,1)  = F(i,1); 
  B(2*i-1,2)  = F(i,2); 
  B(2*i-1,3)  = F(i,3);
  B(2*i-1,4)  = 1;
  B(2*i-1,9)  =-F(i,1)*L(i,1);
  B(2*i-1,10) =-F(i,2)*L(i,1);
  B(2*i-1,11) =-F(i,3)*L(i,1);
  B(2*i,5)    = F(i,1);
  B(2*i,6)    = F(i,2);
  B(2*i,7)    = F(i,3);
  B(2*i,8)    = 1;
  B(2*i,9)  =-F(i,1)*L(i,2);
  B(2*i,10) =-F(i,2)*L(i,2);
  B(2*i,11) =-F(i,3)*L(i,2);
end

% Cut the lines out of B and C including the control points to be discarded
Cutlines=[Cut.*2-1, Cut.*2];
B([Cutlines],:)=[];
C([Cutlines],:)=[];

% Solution for the coefficients
A=B\C; % note that \ is a left matrix divide
D=B*A;
R=C-D;
res=norm(R); avgres=res/size(R,1)^0.5;
rawres=R;



function [b,avgres]=mdlt1(pk,sk)

% function [b,avgres]=mdlt1(pk,sk)
%
%Input:		pk-matrix containing global coordinates (X,Y,Z) of the ith point
%				e.g. pk(i,1), pk(i,2), pk(i,3)
%				sk-matrix containing image coordinates (u,v) of the ith point
%    			e.g. sk(i,1), sk(i,2)
%Output:		sets of 11 DLT parameters for all iterations
%				The code is far from being optimal and many improvements are to come.
%
%Author: 	Tomislav Pribanic, University of Zagreb, Croatia
%e-mail:		Tomislav.Pribanic@zesoi.fer.hr
%				Any comments and suggestions would be more than welcome.
%Date:		September 1999
%Version: 	1.0
%
%Function uses MDLT method adding non-linear constraint:
%(L1*L5+L2*L6+L3*L7)*(L9^2+L10^2+L11^2)=(L1*L9+L2*L10+L3*L11)*(L5*L9+L6*L10+L7*L11) (1)
%(assuring orthogonality of transformation matrix and eliminating redundant parametar) to the
%linear system of DLT represented by basic DLT equations:
%							u=(L1*X+L2*Y+L3*Z+L4)/(L9*X+L10*Y+L11*Z+1);	(2)
%							v=(L5*X+L6*Y+L7*Z+L8)/(L9*X+L10*Y+L11*Z+1);	(3).
%(u,v)	image coordinates in digitizer units
%L1...L11 	DLT parameters
%(X,Y,Z)	object space coordinates
%Once the non-linear equation (1) was solved for the L1 parameter, it was substituted
% for L1 in the equation (2) and now only 10 DLT parameters appear.
%
%The obtained non-linear system was solved with the following algorithm (Newton's method):
%equations u=f(L2-L11) (2) and v=g(L2-L11) (3) were expressed using truncated Taylor
%series expansion (up to the first derivative) resulting again with 
%the set of linearized equations (for particular point we have):
%	u=fo+pd(fo)/pd(L2)*d(L2)+...+pd(fo)/pd(L11)*d(L11)		(4)
%	v=go+pd(go)/pd(L2)*d(L2)+...+pd(go)/pd(L11)*d(L11)		(5)
%pd- partial derivative
%d-differential
%fo, go, pd(fo)/pd(L2)...pd(fo)/pd(L11)*d(L11) and  pd(go)/pd(L2)...pd(go)/pd(L11) are
%current estimates acquired by previous iteration.
%Initial estimates are provided by conventional 11 DLT parameter method.
%
%Therefore standard linear least square technique can be applied to calculate d(L2)...d(L11)
%elements.
%Each element is in fact d(Li)=Li(current iteration)-Li(previous iteration, known from before).
%Li's of current iteration can be than substituted for a new estimates in (4) and (5) until
%all elements of d(Li's) are satisfactory small.

%REFERENCES:

%1. The paper explains linear and non-linear MDLT.
%	 The function reflects only the linear MDLT (no symmetrical or
%	 asymmetrical lens distortion parameters included).

%   Hatze H. HIGH-PRECISION THREE-DIMENSIONAL PHOTOGRAMMETRIC CALIBRATION
%   AND OBJECT SPACE RECONSTRUCTION USING A MODIFIED DLT-APPROACH.
%   J. Biomechanics, 1988, 21, 533-538

%2. The paper shows the particular mathematical linearization technique for 
%	 solving non-linear nature of equations due to adding non-linear constrain.

%	 Miller N. R., Shapiro R., and McLaughlin T. M. A TECHNIQUE FOR OBTAINING
%	 SPATIAL KINEMATIC PARAMETERS OF SEGMENTS OF BIOMECHANICAL SYSTEMS 
%	 FROM CINEMATOGRAPHIC DATA. J. Biomechanics, 1980, 13, 535-547




%Input:		pk-matrix containing global coordinates (X,Y,Z) of the ith point
%				e.g. pk(i,1), pk(i,2), pk(i,3)
%				sk-matrix containing image coordinates (u,v) of the ith point
%    			e.g. sk(i,1), sk(i,2)
%Output:		sets of 11 DLT parameters for all iterations
%				The code is far from being optimal and many improvements are to come.

%[a]*[b]=[c]

% automatic removal of NaN points added by Ty Hedrick 9/14/00
Cut=[];
for i=1:size(sk,1)
  if isnan(sk(i,1))==1
    Cut(1,size(Cut,2)+1)=i;
  end
end
%Cutlines=[Cut.*2-1, Cut.*2]
pk([Cut],:)=[];
sk([Cut],:)=[];

m=size(pk,1);	% number of calibration points
c=sk';c=c(:);	% re-grouping image coordinates in one column
ite=10; 			%number of iterations

% Solve 'ortogonality' equation (1) for L1
L1=solve('(L1*L5+L2*L6+L3*L7)*(L9^2+L10^2+L11^2)=(L1*L9+L2*L10+L3*L11)*(L5*L9+L6*L10+L7*L11)','L1');
%initialize basic DLT equations (2) and (3)
u=sym('(L1*X+L2*Y+L3*Z+L4)/(L9*X+L10*Y+L11*Z+1)');
v=sym('(L5*X+L6*Y+L7*Z+L8)/(L9*X+L10*Y+L11*Z+1)');
%elimenate L1 out of equation (2)using the (1)
jed1=[ char(L1) '=L1'];
jed2=[ char(u) '=u'];
[L1,u]=solve( jed1, jed2,'L1,u');

%Find the first partial derivatives of (4) and (5)
%f(1)=diff(u,'L1');g(1)=diff(v,'L1'); 
%L1 was chosen to be eliminated. In case other parameter (for example L2) is chosen
%the above line should become active and the appropriate one passive instead.
f(1)=diff(u,'L2');g(1)=diff(v,'L2');
f(2)=diff(u,'L3');g(2)=diff(v,'L3');
f(3)=diff(u,'L4');g(3)=diff(v,'L4');
f(4)=diff(u,'L5');g(4)=diff(v,'L5');
f(5)=diff(u,'L6');g(5)=diff(v,'L6');
f(6)=diff(u,'L7');g(6)=diff(v,'L7');
f(7)=diff(u,'L8');g(7)=diff(v,'L8');
f(8)=diff(u,'L9');g(8)=diff(v,'L9');
f(9)=diff(u,'L10');g(9)=diff(v,'L10');
f(10)=diff(u,'L11');g(10)=diff(v,'L11');

%Find the inital estimates using conventional DLT method
for i=1:m
   a(2*i-1,1)=pk(i,1);
   a(2*i-1,2)=pk(i,2);
   a(2*i-1,3)=pk(i,3);
   a(2*i-1,4)=1;
   a(2*i-1,9)=-pk(i,1)*sk(i,1);
   a(2*i-1,10)=-pk(i,2)*sk(i,1);
   a(2*i-1,11)=-pk(i,3)*sk(i,1);
   a(2*i,5)=pk(i,1);
   a(2*i,6)=pk(i,2);
   a(2*i,7)=pk(i,3);
   a(2*i,8)=1;
   a(2*i,9)=-pk(i,1)*sk(i,2);
   a(2*i,10)=-pk(i,2)*sk(i,2);
   a(2*i,11)=-pk(i,3)*sk(i,2);
end
%Conventional DLT parameters
b=a\c;
%Take the intial estimates for parameters
%L1=b(1); L1 is excluded.
L2=b(2);L3=b(3);L4=b(4);L5=b(5);L6=b(6);
L7=b(7);L8=b(8);L9=b(9);L10=b(10);L11=b(11);

%Save a for use in generating residuals
a_init=a;
clear a b c

%Perform the linear least square technique on the system of equations made from (4) and (5)
%IMPORTANT NOTE:
%the elements of matrices a and c (see below) are expressions based on (4) and (5) and part
%of program which calculates the partial derivatives (from line %Find the first partial...
%to the line %Find the inital...)
%However the elements itself are computed outside the function since the computation itself
%(for instance via MATLAB eval function: a(2*i-1,1)=eval(f(1));a(2*i-1,2)=eval(f(2)); etc.
%c(2*i-1)=sk(i,1)-eval(u);c(2*i)=sk(i,2)-eval(v);)is only time consuming and unnecessary.
%Thus the mentioned part of the program has only educational/historical purpose and 
%can be excluded for practical purposes

for k=1:ite  %k-th iteartion
   %Form matrices a and c
   for i=1:m	%i-th point
      X=pk(i,1);Y=pk(i,2);Z=pk(i,3);
      %first row of the i-th point; contribution of (4) equation
      a(2*i-1,1)=(-X*L6*L9^2-X*L6*L11^2+X*L10*L5*L9+X*L10*L7*L11+Y*L5*L10^2+Y*L5*L11^2-Y*L9*L6*L10-Y*L9*L7*L11)/(L5*L11^2+L5*L10^2+L9*X*L5*L10^2+L9*X*L5*L11^2-L9^2*X*L6*L10-L9^2*X*L7*L11+L10^3*Y*L5+L10*Y*L5*L11^2-L10^2*Y*L9*L6-L10*Y*L9*L7*L11+L11*Z*L5*L10^2+L11^3*Z*L5-L11*Z*L9*L6*L10-L11^2*Z*L9*L7-L9*L6*L10-L9*L7*L11);
      a(2*i-1,2)=(-X*L7*L9^2-X*L7*L10^2+X*L11*L5*L9+X*L11*L6*L10+Z*L5*L10^2+Z*L5*L11^2-Z*L9*L6*L10-Z*L9*L7*L11)/(L5*L11^2+L5*L10^2+L9*X*L5*L10^2+L9*X*L5*L11^2-L9^2*X*L6*L10-L9^2*X*L7*L11+L10^3*Y*L5+L10*Y*L5*L11^2-L10^2*Y*L9*L6-L10*Y*L9*L7*L11+L11*Z*L5*L10^2+L11^3*Z*L5-L11*Z*L9*L6*L10-L11^2*Z*L9*L7-L9*L6*L10-L9*L7*L11);
      a(2*i-1,3)=(L5*L10^2+L5*L11^2-L9*L6*L10-L9*L7*L11)/(L5*L11^2+L5*L10^2+L9*X*L5*L10^2+L9*X*L5*L11^2-L9^2*X*L6*L10-L9^2*X*L7*L11+L10^3*Y*L5+L10*Y*L5*L11^2-L10^2*Y*L9*L6-L10*Y*L9*L7*L11+L11*Z*L5*L10^2+L11^3*Z*L5-L11*Z*L9*L6*L10-L11^2*Z*L9*L7-L9*L6*L10-L9*L7*L11);
      a(2*i-1,4)=(L4*L10^2+L4*L11^2+X*L2*L10*L9+X*L3*L11*L9+L2*Y*L10^2+L2*Y*L11^2+L3*Z*L10^2+L3*Z*L11^2)/(L5*L11^2+L5*L10^2+L9*X*L5*L10^2+L9*X*L5*L11^2-L9^2*X*L6*L10-L9^2*X*L7*L11+L10^3*Y*L5+L10*Y*L5*L11^2-L10^2*Y*L9*L6-L10*Y*L9*L7*L11+L11*Z*L5*L10^2+L11^3*Z*L5-L11*Z*L9*L6*L10-L11^2*Z*L9*L7-L9*L6*L10-L9*L7*L11)-(L4*L5*L10^2+L4*L5*L11^2-X*L2*L6*L9^2-X*L2*L6*L11^2-X*L3*L7*L9^2-X*L3*L7*L10^2+X*L2*L10*L5*L9+X*L2*L10*L7*L11+X*L3*L11*L5*L9+X*L3*L11*L6*L10+L2*Y*L5*L10^2+L2*Y*L5*L11^2-L2*Y*L9*L6*L10-L2*Y*L9*L7*L11+L3*Z*L5*L10^2+L3*Z*L5*L11^2-L3*Z*L9*L6*L10-L3*Z*L9*L7*L11-L4*L9*L6*L10-L4*L9*L7*L11)/(L5*L11^2+L5*L10^2+L9*X*L5*L10^2+L9*X*L5*L11^2-L9^2*X*L6*L10-L9^2*X*L7*L11+L10^3*Y*L5+L10*Y*L5*L11^2-L10^2*Y*L9*L6-L10*Y*L9*L7*L11+L11*Z*L5*L10^2+L11^3*Z*L5-L11*Z*L9*L6*L10-L11^2*Z*L9*L7-L9*L6*L10-L9*L7*L11)^2*(L11^2+L10^2+L9*X*L10^2+L9*X*L11^2+L10^3*Y+L10*Y*L11^2+L11*Z*L10^2+L11^3*Z);
      a(2*i-1,5)=(-X*L2*L9^2-X*L2*L11^2+X*L3*L11*L10-L2*Y*L9*L10-L3*Z*L9*L10-L4*L9*L10)/(L5*L11^2+L5*L10^2+L9*X*L5*L10^2+L9*X*L5*L11^2-L9^2*X*L6*L10-L9^2*X*L7*L11+L10^3*Y*L5+L10*Y*L5*L11^2-L10^2*Y*L9*L6-L10*Y*L9*L7*L11+L11*Z*L5*L10^2+L11^3*Z*L5-L11*Z*L9*L6*L10-L11^2*Z*L9*L7-L9*L6*L10-L9*L7*L11)-(L4*L5*L10^2+L4*L5*L11^2-X*L2*L6*L9^2-X*L2*L6*L11^2-X*L3*L7*L9^2-X*L3*L7*L10^2+X*L2*L10*L5*L9+X*L2*L10*L7*L11+X*L3*L11*L5*L9+X*L3*L11*L6*L10+L2*Y*L5*L10^2+L2*Y*L5*L11^2-L2*Y*L9*L6*L10-L2*Y*L9*L7*L11+L3*Z*L5*L10^2+L3*Z*L5*L11^2-L3*Z*L9*L6*L10-L3*Z*L9*L7*L11-L4*L9*L6*L10-L4*L9*L7*L11)/(L5*L11^2+L5*L10^2+L9*X*L5*L10^2+L9*X*L5*L11^2-L9^2*X*L6*L10-L9^2*X*L7*L11+L10^3*Y*L5+L10*Y*L5*L11^2-L10^2*Y*L9*L6-L10*Y*L9*L7*L11+L11*Z*L5*L10^2+L11^3*Z*L5-L11*Z*L9*L6*L10-L11^2*Z*L9*L7-L9*L6*L10-L9*L7*L11)^2*(-L9^2*X*L10-L10^2*Y*L9-L11*Z*L9*L10-L9*L10);
      a(2*i-1,6)=(-X*L3*L9^2-X*L3*L10^2+X*L2*L10*L11-L2*Y*L9*L11-L3*Z*L9*L11-L4*L9*L11)/(L5*L11^2+L5*L10^2+L9*X*L5*L10^2+L9*X*L5*L11^2-L9^2*X*L6*L10-L9^2*X*L7*L11+L10^3*Y*L5+L10*Y*L5*L11^2-L10^2*Y*L9*L6-L10*Y*L9*L7*L11+L11*Z*L5*L10^2+L11^3*Z*L5-L11*Z*L9*L6*L10-L11^2*Z*L9*L7-L9*L6*L10-L9*L7*L11)-(L4*L5*L10^2+L4*L5*L11^2-X*L2*L6*L9^2-X*L2*L6*L11^2-X*L3*L7*L9^2-X*L3*L7*L10^2+X*L2*L10*L5*L9+X*L2*L10*L7*L11+X*L3*L11*L5*L9+X*L3*L11*L6*L10+L2*Y*L5*L10^2+L2*Y*L5*L11^2-L2*Y*L9*L6*L10-L2*Y*L9*L7*L11+L3*Z*L5*L10^2+L3*Z*L5*L11^2-L3*Z*L9*L6*L10-L3*Z*L9*L7*L11-L4*L9*L6*L10-L4*L9*L7*L11)/(L5*L11^2+L5*L10^2+L9*X*L5*L10^2+L9*X*L5*L11^2-L9^2*X*L6*L10-L9^2*X*L7*L11+L10^3*Y*L5+L10*Y*L5*L11^2-L10^2*Y*L9*L6-L10*Y*L9*L7*L11+L11*Z*L5*L10^2+L11^3*Z*L5-L11*Z*L9*L6*L10-L11^2*Z*L9*L7-L9*L6*L10-L9*L7*L11)^2*(-L9^2*X*L11-L10*Y*L9*L11-L11^2*Z*L9-L9*L11);
      a(2*i-1,7)=0;
      a(2*i-1,8)=(-2*X*L2*L6*L9-2*X*L3*L7*L9+X*L2*L10*L5+X*L3*L11*L5-L2*Y*L6*L10-L2*Y*L7*L11-L3*Z*L6*L10-L3*Z*L7*L11-L4*L6*L10-L4*L7*L11)/(L5*L11^2+L5*L10^2+L9*X*L5*L10^2+L9*X*L5*L11^2-L9^2*X*L6*L10-L9^2*X*L7*L11+L10^3*Y*L5+L10*Y*L5*L11^2-L10^2*Y*L9*L6-L10*Y*L9*L7*L11+L11*Z*L5*L10^2+L11^3*Z*L5-L11*Z*L9*L6*L10-L11^2*Z*L9*L7-L9*L6*L10-L9*L7*L11)-(L4*L5*L10^2+L4*L5*L11^2-X*L2*L6*L9^2-X*L2*L6*L11^2-X*L3*L7*L9^2-X*L3*L7*L10^2+X*L2*L10*L5*L9+X*L2*L10*L7*L11+X*L3*L11*L5*L9+X*L3*L11*L6*L10+L2*Y*L5*L10^2+L2*Y*L5*L11^2-L2*Y*L9*L6*L10-L2*Y*L9*L7*L11+L3*Z*L5*L10^2+L3*Z*L5*L11^2-L3*Z*L9*L6*L10-L3*Z*L9*L7*L11-L4*L9*L6*L10-L4*L9*L7*L11)/(L5*L11^2+L5*L10^2+L9*X*L5*L10^2+L9*X*L5*L11^2-L9^2*X*L6*L10-L9^2*X*L7*L11+L10^3*Y*L5+L10*Y*L5*L11^2-L10^2*Y*L9*L6-L10*Y*L9*L7*L11+L11*Z*L5*L10^2+L11^3*Z*L5-L11*Z*L9*L6*L10-L11^2*Z*L9*L7-L9*L6*L10-L9*L7*L11)^2*(X*L5*L10^2+X*L5*L11^2-2*L9*X*L6*L10-2*L9*X*L7*L11-L10^2*Y*L6-L10*Y*L7*L11-L11*Z*L6*L10-L11^2*Z*L7-L6*L10-L7*L11);
      a(2*i-1,9)=(2*L4*L5*L10-2*X*L3*L7*L10+X*L2*L5*L9+X*L2*L7*L11+X*L3*L11*L6+2*L2*Y*L5*L10-L2*Y*L9*L6+2*L3*Z*L5*L10-L3*Z*L9*L6-L4*L9*L6)/(L5*L11^2+L5*L10^2+L9*X*L5*L10^2+L9*X*L5*L11^2-L9^2*X*L6*L10-L9^2*X*L7*L11+L10^3*Y*L5+L10*Y*L5*L11^2-L10^2*Y*L9*L6-L10*Y*L9*L7*L11+L11*Z*L5*L10^2+L11^3*Z*L5-L11*Z*L9*L6*L10-L11^2*Z*L9*L7-L9*L6*L10-L9*L7*L11)-(L4*L5*L10^2+L4*L5*L11^2-X*L2*L6*L9^2-X*L2*L6*L11^2-X*L3*L7*L9^2-X*L3*L7*L10^2+X*L2*L10*L5*L9+X*L2*L10*L7*L11+X*L3*L11*L5*L9+X*L3*L11*L6*L10+L2*Y*L5*L10^2+L2*Y*L5*L11^2-L2*Y*L9*L6*L10-L2*Y*L9*L7*L11+L3*Z*L5*L10^2+L3*Z*L5*L11^2-L3*Z*L9*L6*L10-L3*Z*L9*L7*L11-L4*L9*L6*L10-L4*L9*L7*L11)/(L5*L11^2+L5*L10^2+L9*X*L5*L10^2+L9*X*L5*L11^2-L9^2*X*L6*L10-L9^2*X*L7*L11+L10^3*Y*L5+L10*Y*L5*L11^2-L10^2*Y*L9*L6-L10*Y*L9*L7*L11+L11*Z*L5*L10^2+L11^3*Z*L5-L11*Z*L9*L6*L10-L11^2*Z*L9*L7-L9*L6*L10-L9*L7*L11)^2*(2*L5*L10+2*L9*X*L5*L10-L9^2*X*L6+3*L10^2*Y*L5+Y*L5*L11^2-2*L10*Y*L9*L6-Y*L9*L7*L11+2*L11*Z*L5*L10-L11*Z*L9*L6-L9*L6);
      a(2*i-1,10)=(2*L4*L5*L11-2*X*L2*L6*L11+X*L2*L10*L7+X*L3*L5*L9+X*L3*L6*L10+2*L2*Y*L5*L11-L2*Y*L9*L7+2*L3*Z*L5*L11-L3*Z*L9*L7-L4*L9*L7)/(L5*L11^2+L5*L10^2+L9*X*L5*L10^2+L9*X*L5*L11^2-L9^2*X*L6*L10-L9^2*X*L7*L11+L10^3*Y*L5+L10*Y*L5*L11^2-L10^2*Y*L9*L6-L10*Y*L9*L7*L11+L11*Z*L5*L10^2+L11^3*Z*L5-L11*Z*L9*L6*L10-L11^2*Z*L9*L7-L9*L6*L10-L9*L7*L11)-(L4*L5*L10^2+L4*L5*L11^2-X*L2*L6*L9^2-X*L2*L6*L11^2-X*L3*L7*L9^2-X*L3*L7*L10^2+X*L2*L10*L5*L9+X*L2*L10*L7*L11+X*L3*L11*L5*L9+X*L3*L11*L6*L10+L2*Y*L5*L10^2+L2*Y*L5*L11^2-L2*Y*L9*L6*L10-L2*Y*L9*L7*L11+L3*Z*L5*L10^2+L3*Z*L5*L11^2-L3*Z*L9*L6*L10-L3*Z*L9*L7*L11-L4*L9*L6*L10-L4*L9*L7*L11)/(L5*L11^2+L5*L10^2+L9*X*L5*L10^2+L9*X*L5*L11^2-L9^2*X*L6*L10-L9^2*X*L7*L11+L10^3*Y*L5+L10*Y*L5*L11^2-L10^2*Y*L9*L6-L10*Y*L9*L7*L11+L11*Z*L5*L10^2+L11^3*Z*L5-L11*Z*L9*L6*L10-L11^2*Z*L9*L7-L9*L6*L10-L9*L7*L11)^2*(2*L5*L11+2*L9*X*L5*L11-L9^2*X*L7+2*L10*Y*L5*L11-L10*Y*L9*L7+Z*L5*L10^2+3*L11^2*Z*L5-Z*L9*L6*L10-2*L11*Z*L9*L7-L9*L7);
      %second row of the i-th point; contribution of (5) equation
      a(2*i,1)=0;
      a(2*i,2)=0;
      a(2*i,3)=0;
      a(2*i,4)=X/(L9*X+L10*Y+L11*Z+1);
      a(2*i,5)=Y/(L9*X+L10*Y+L11*Z+1);
      a(2*i,6)=Z/(L9*X+L10*Y+L11*Z+1);
      a(2*i,7)=1/(L9*X+L10*Y+L11*Z+1);
      a(2*i,8)=-(L5*X+L6*Y+L7*Z+L8)/(L9*X+L10*Y+L11*Z+1)^2*X;
      a(2*i,9)=-(L5*X+L6*Y+L7*Z+L8)/(L9*X+L10*Y+L11*Z+1)^2*Y;
      a(2*i,10)=-(L5*X+L6*Y+L7*Z+L8)/(L9*X+L10*Y+L11*Z+1)^2*Z;
      %analogicaly for c matrice
      c(2*i-1)=sk(i,1)-(L4*L5*L10^2+L4*L5*L11^2-X*L2*L6*L9^2-X*L2*L6*L11^2-X*L3*L7*L9^2-X*L3*L7*L10^2+X*L2*L10*L5*L9+X*L2*L10*L7*L11+X*L3*L11*L5*L9+X*L3*L11*L6*L10+L2*Y*L5*L10^2+L2*Y*L5*L11^2-L2*Y*L9*L6*L10-L2*Y*L9*L7*L11+L3*Z*L5*L10^2+L3*Z*L5*L11^2-L3*Z*L9*L6*L10-L3*Z*L9*L7*L11-L4*L9*L6*L10-L4*L9*L7*L11)/(L5*L11^2+L5*L10^2+L9*X*L5*L10^2+L9*X*L5*L11^2-L9^2*X*L6*L10-L9^2*X*L7*L11+L10^3*Y*L5+L10*Y*L5*L11^2-L10^2*Y*L9*L6-L10*Y*L9*L7*L11+L11*Z*L5*L10^2+L11^3*Z*L5-L11*Z*L9*L6*L10-L11^2*Z*L9*L7-L9*L6*L10-L9*L7*L11);
      c(2*i)=sk(i,2)-(L5*X+L6*Y+L7*Z+L8)/(L9*X+L10*Y+L11*Z+1);
   end
   c=c';c=c(:); %regrouping in one column
   b=a\c; %10 MDLT parameters of the k-the iteration
   
   % Prepare the estimates for a new iteration
   L2=b(1)+L2;L3=b(2)+L3;L4=b(3)+L4;L5=b(4)+L5;L6=b(5)+L6;
   L7=b(6)+L7;L8=b(7)+L8;L9=b(8)+L9;L10=b(9)+L10;L11=b(10)+L11;
   % Calculate L1 based on equation (1)and 'save' the parameters of the k-th iteration
   dlt(k,:)=[eval(L1) L2 L3 L4 L5 L6 L7 L8 L9 L10 L11];
   %%disp('Number of iterations performed'),k
   clear a b c
end
%b=dlt;%return all sets of 11 DLT parameters for all iterations
b=dlt(k,:)';%return last DLT set in KineMat orientation

% calculate residuals - added by Ty Hedrick
% note that this currently uses the initial estimate of the DLT parameters rather than the final set
D=a_init*b;
sk_l=sk';
sk_l=sk_l(:); 
R=sk_l-D;
res=norm(R); avgres=res/size(R,1)^.5;


