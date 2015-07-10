clear;clc;
cd('/Users/joshsalvi/Documents/Lab/Lab/Videos/Zebrafish/High Speed/')
eventnum = 10;
mov = aviread(['Event' num2str(eventnum) '.avi']);      % import video
vidobj=VideoReader(['Event' num2str(eventnum) '.avi']); % import VideoReader file for metadata
nFrames = vidobj.NumberOfFrames;                        % extract number of frames in video
vidHeight = vidobj.Height;                              % video height (px)
vidWidth = vidobj.Width;                                % video dimensions (px)
FrameRate = vidobj.FrameRate;                           % frame rate (frames/sec)
dt = 1/FrameRate;                                       % time step (sec/frame)
tvec = 0:dt:nFrames/FrameRate-dt;                       % generate a time vector (sec)

%% Rotate the video
rotateyn  = 1;rotang=0;
close all;figure(1);
while rotateyn ==1
    imshow(imrotate(histeq(mov(1,1).cdata),rotang));
    rotang = input('Angle of rotation: ');
    imshow(imrotate(histeq(mov(1,1).cdata),rotang));
    rotateyn = input('Rotate again (1=yes)? ');
    rotated = 1;
end
%% Subsample the image to only one bundle
clear subframe
close all; clc
if exist('rotang')==0
    rotang=0;
end

equalyn = input('Equalize (1=yes)? ');
disp('Draw ROI...');
if equalyn == 1
    [~,t1]  = histeq(mov(1).cdata);
[cropframe rect] = imcrop(imrotate(histeq(mov(1,1).cdata,t1),rotang));  %ask user to crop image to one bundle, save the dimensions of the cropping rectangle
rect_rounded = round(rect);
cellnum = input('Cell number: ');
for i = 1:size(mov,2)
    eval(['subframe(:,:,' num2str(i) ') = imcrop(imrotate(histeq(mov(i).cdata,t1),rotang),rect_rounded);']);
    if mod(i,100) == 0
        disp([num2str(i/size(mov,2)*100) '%...']);
    end
end
disp('Finished.');
else
    [cropframe rect] = imcrop(mov(1,1).cdata);  %ask user to crop image to one bundle, save the dimensions of the cropping rectangle
rect_rounded = round(rect);
cellnum = input('Cell number: ');
for i = 1:size(mov,2)
    eval(['subframe(:,:,' num2str(i) ') = imcrop(imrotate(mov(i).cdata,rotang),rect_rounded);']);
    if mod(i,100) == 0
        disp([num2str(i/size(mov,2)*100) '%...']);
    end
end
disp('Finished.');
end



%% Threshold the image (only keep values above a threshold)
clc;
disp('Analyzing...');
maximum = max(max(max(subframe(:,:,:)))); % The highest value in the whole subframed movie
minimum = min(min(min(subframe(:,:,:)))); % The minimum value in the whole subframed movie
%thresh_level = minimum + (maximum - minimum) * 0.4; 
thresh_level = 250;

subframe_copy = subframe;
subframe_copy(subframe_copy < thresh_level) = 0;
threshold = subframe_copy;

xbars = zeros(size(threshold,3),1);
ybars = zeros(size(threshold,3),1);

for i = 1:size(threshold,3)
    image = threshold(:,:,i);                   % define the current frame
    image = image > 1;                          % make the object all 1's; logical
    image_bw = imfill(image,'holes');           % fill in the object (any discontinuous parts are filled in)
    image_bw2 = bwareaopen(image_bw, 10);       % remove any points that are not connected to at least 20 in total
    image_L = bwlabel(image_bw2);               % label each continous object with a number (in case there are multiple)
    if sum(sum(image_L)) == 0
        image_L = bwlabel(image_bw);
    end
    image_s = regionprops(image_L, 'PixelIdxList', 'PixelList');    % Get the index of pixels, and their x,y coordinates
    idx = image_s(1).PixelIdxList;              % put the indexes into a new variable
    sum_region = sum(image(idx));               % sum to get the total intensity of all pixels in the object
    x = image_s(1).PixelList(:,1);              % get the x coordinates of all pixels in the object
    y = image_s(1).PixelList(:,2);              % get the y coordinates of all pixels in the object
    xbar = sum(x .* double(image(idx))) / sum_region;   % calculate the position of the mean intensity in x
    ybar = sum(y .* double(image(idx))) / sum_region;   % calculate the position of the mean intensity in x
    xbars(i,1) = xbar;
    ybars(i,1) = ybar;
end
disp('Plotting...');
close all;
figure(1);
subplot(2,2,1);plot(tvec,xbars);xlabel('Time (s)');ylabel('X');
subplot(2,2,2);pwelch(xbars,[],[],[],FrameRate)
subplot(2,2,3);plot(tvec,ybars);xlabel('Time (s)');ylabel('Y');
subplot(2,2,4);pwelch(ybars,[],[],[],FrameRate)
disp('Complete.');
%{
filtyn = input('Remove peaks (1=yes)? ');
while filtyn == 1
    threshfiltx = input('Threshold in X: ');
    threshfilty = input('Threshold in Y: ');
    xbars2=xbars;ybars2=ybars;tvecx=tvec; tvecy=tvec;
    tvecx(xbars2<threshfiltx) = [];tvecy(ybars2<threshfilty) = [];
    xbars2(xbars2<threshfiltx) = [];ybars2(ybars2<threshfilty) = [];
    figure(1);
    subplot(2,2,1);hold on;plot(tvecx,xbars2,'r');xlabel('Time (s)');ylabel('X');
    subplot(2,2,2);hold on;pwelch(xbars2,[],[],[],FrameRate)
    subplot(2,2,3);hold on;plot(tvecy,ybars2,'r');xlabel('Time (s)');ylabel('Y');
    subplot(2,2,4);hold on;pwelch(ybars2,[],[],[],FrameRate);
    filtyn = input('Remove peaks again (1=yes)? ');
end

%}
%% filter the plots
thr = 0;
threshold2=threshold;subframe2=subframe;
ybars2=ybars;xbars2=xbars;tvec2=tvec;
threshold2(:,:,gradient(ybars2)>thr)=[];
subframe2(:,:,gradient(ybars2)>thr)=[];
tvec2(gradient(ybars2)>thr) = [];
xbars2(gradient(ybars2)>thr) = [];
ybars2(gradient(ybars2)>thr) = [];
tvec2(gradient(ybars2)<-thr) = [];
xbars2(gradient(ybars2)<-thr) = [];
threshold2(:,:,gradient(ybars2)<-thr)=[];
subframe2(:,:,gradient(ybars2)<-thr)=[];
ybars2(gradient(ybars2)<-thr) = [];
ybars_old=ybars;xbars_old=xbars;tvec_old=tvec;
ybars=ybars2;xbars=xbars2;tvec=tvec2;

%% Reset to original
ybars=ybars_old;
xbars=xbars_old;
tvec=tvec_old;
%% Create an equalized video
for j = 1:nFrames
    mov2(j).cdata = histeq(mov(j).cdata);                       % equalize all frames
    mov2(j).colormap = mov(j).colormap;
end
slowedyn = input('Slow down the video (1=yes)? ');
if slowedyn ==1
    slowfactor = input('Factor (100 = 100X slower): ');
    vidobj2.FrameRate = round(FrameRate/slowfactor);
    vidobj2 = VideoWriter(['Event' num2str(eventnum) '-eq-slowed' num2str(slowfactor) 'X.avi']);       % create video writer object
    vidObj2.Duration = nFrames/vidobj2.FrameRate-1/vidobj2.FrameRate;   % include metadata
else
    vidobj2.FrameRate = FrameRate;
    vidobj2 = VideoWriter(['Event' num2str(eventnum) '-eq.avi']);   % create video writer object
    vidObj2.Duration = tvec(end);                                   % include metadata
end
open(vidobj2);                                                  % open video writer object
writeVideo(vidobj2,mov2);                                       % write the video
close(vidobj2);                                                 % close the video writer object

%%
%{
y1 = ybars(1:1000,1);
y2 = ybars(1001:2000,1);
y3 = ybars(2001:3000,1);
y4 = ybars(3001:4000,1);
y_average = (y1 + y2 + y3 + y4) / 4; 


x1 = xbars(1:500,1);
x2 = xbars(501:1000,1);
x3 = xbars(1001:1500,1);
x4 = xbars(1501:2000,1);
x_average = (x1 + x2 + x3 + x4) / 4; 
%}
%% Create a difference image
for j = 2:nFrames
    movdiff(:,:,j-1) = histeq(threshold(:,:,j),t1) - histeq(threshold(:,:,j-1),t1);
end

%% Save the data

path1 = cd;
if equalyn == 0 
    save([path1 '/' 'Event' num2str(eventnum) '-analyzed-cell' num2str(cellnum) '.mat'],'xbars','ybars','rect','rect_rounded','nFrames','vidHeight','vidWidth','FrameRate','dt','tvec','vidobj','movdiff');
else
    save([path1 '/' 'Event' num2str(eventnum) '-analyzed-cell' num2str(cellnum) '-equalized.mat'],'xbars','ybars','rect','rect_rounded','nFrames','vidHeight','vidWidth','FrameRate','dt','tvec','vidobj','movdiff');
end
    
%%
writeyn = input('Write video (1=yes)? ');
if writeyn ==1
writerObj = VideoWriter(['Event' num2str(eventnum) '-analysis-cell' num2tr(cellnum) '.avi']);
writerObj.FrameRate = FrameRate;
open(writerObj);
end

set(0,'DefaultFigureWindowStyle','default')
h2=figure;                          % set the figure for movie making
spnx=subplot(2,2,3); hold on;plot(tvec,xbars,'k')  % initial plot of time series in black
axis([0 tvec(end) min(xbars)*1.05 max(xbars)*1.05]);        % set axes [xmin xmax ymin ymax]
xlabel('Time (sec)');title('X');
snpx = get(spnx, 'pos');
set(spnx, 'Position', [0.1*snpx(1) 1*snpx(2) 1.4*snpx(3) 1*snpx(4)]);set(spnx,'Yticklabel','');
spny=subplot(2,2,4); hold on;plot(tvec,ybars,'k')  % initial plot of time series in black
axis([0 tvec(end) min(ybars)*1.05 max(ybars)*1.05]);        % set axes [xmin xmax ymin ymax]
xlabel('Time (sec)');title('Y');
snpy = get(spny, 'pos');
set(spny, 'Position', [0.9*snpy(1) 1*snpy(2) 1.4*snpy(3) 1*snpy(4)]);set(spny,'Yticklabel','');

for i = 1:nFrames                   % loop through each frame
    
    image = threshold(:,:,i);                   % define the current frame
    image = image > 1;                          % make the object all 1's; logical
    image_bw = imfill(image,'holes');           % fill in the object (any discontinuous parts are filled in
    image_bw2 = bwareaopen(image_bw, 20);        % remove any points that are not connected to at least 20 in total
    image_L = bwlabel(image_bw2);                % label each continous object with a number (in case there are multiple)
    if sum(sum(image_L)) == 0
        image_L = bwlabel(image_bw);
    end
sph=subplot(2,2,1);hold off;
%J=roifill(vidmov(i).cdata(:,:,1),ROI2{j});
J=subframe(:,:,i);
imshow(J);colormap('gray');    % plot video frame
hold on;plot(xbars(i),ybars(i),'r.','MarkerSize',40);
sph2=subplot(2,2,2);hold off;
J=image_L;
%J = movdiff(:,:,i);
imshow(J);colormap('gray');    % plot video frame
hold on;plot(xbars(i),ybars(i),'g.','MarkerSize',40);
spnx=subplot(2,2,3); hold on;plot(tvec,xbars,'k'); hold on; plot(tvec(1:i),xbars(1:i),'r');  
axis([0 tvec(end) min(xbars)*1.05 max(xbars)*1.05]);        % set axes [xmin xmax ymin ymax]
xlabel('Time (sec)');title('X');
snpx = get(spnx, 'pos');
set(spnx, 'Position', [0.1*snpx(1) 1*snpx(2) 1.4*snpx(3) 1*snpx(4)]);set(spnx,'Yticklabel','');
spny=subplot(2,2,4); hold on;plot(tvec,ybars,'k') ; hold on; plot(tvec(1:i),ybars(1:i),'r');
axis([0 tvec(end) min(ybars)*1.05 max(ybars)*1.05]);        % set axes [xmin xmax ymin ymax]
xlabel('Time (sec)');title('Y');
snpy = get(spny, 'pos');
set(spny, 'Position', [0.9*snpy(1) 1*snpy(2) 1.4*snpy(3) 1*snpy(4)]);set(spny,'Yticklabel','');

h(i) = getframe(h2);                % create object/snapshot of figure frame
if writeyn ==1
writeVideo(writerObj,h(i));         % write to video object
end
end
if writeyn ==1
close(writerObj);                   % close video object
end
