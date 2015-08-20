%% Import Video
% This code imports a video object and then reads the frames.
clear all; close all;
set(0,'DefaultFigureWindowStyle','docked') 
% INPUT the filename of your video
vid_in = '/Users/joshsalvi/Documents/Lab/Lab/Videos/Zebrafish/20150709/20150709-1605-1p5Xms222/Composite_(NTSC)_20150709_1604.mov';
% Be sure that you use one of the formats specified by VideoReader.getFileFormats()
%    .3gp - 3GP File
%    .avi - AVI File
%   .divx - DIVX File
%     .dv - DV File
%    .flc - FLC File
%    .flv - FLV File
%    .m4v - MPEG-4 Video
%    .mj2 - Motion JPEG2000
%    .mkv - MKV File
%    .mov - QuickTime movie
%    .mp4 - MPEG-4
%    .mpg - MPEG-1
% You can convert your videos using a program called HandBrake:
% https://handbrake.fr/downloads.php

vidobj = VideoReader(vid_in);

nFrames = vidobj.NumberOfFrames;
vidHeight = vidobj.Height;
vidWidth = vidobj.Width;

% Construct a 1 x nFrame struct array with cdata (pre-allocate first)
vidmov(1:nFrames) = ...
    struct('cdata',zeros(vidHeight,vidWidth, 3,'uint8'),...
           'colormap',[]);
for i = 1:nFrames
    vidmov(i).cdata = read(vidobj,i);
end
tvec = linspace(0,nFrames/vidobj.FrameRate,nFrames);

%% Draw ROI

%% Play back the video, if you so desire
hf = figure;
set(hf, 'position', [150 150 vidWidth vidHeight])
movie(hf, vidmov, 1, vidobj.FrameRate);


%% Now we can prepare the video for particle tracking and analyze it
tvec = linspace(0,nFrames/vidobj.FrameRate,nFrames);
set(0,'DefaultFigureWindowStyle','docked') 

% We want to have a high-contrast image with bright objects
% Are the objects bright? (1=yes; 0=no);
% Also, note that we are only using the first dimension (:,:,1)
bright = 0;
if bright == 1
    for i = 1:nFrames
        vidmovnew(i).cdata = vidmov(i).cdata(:,:,1);
    end
else
    for i = 1:nFrames
        vidmovnew(i).cdata = 255 - vidmov(i).cdata(:,:,1);
    end
end

% Create a spatial bandpass filter on the image
% Specify a few different values to see what this looks like and rerun the
% program if you so choose. The first number is usually 1 and the second
% number typically refers to the diameter of the object in pixels you are
% tracking.
bpl=1; colormap('gray');
figure(1); subplot(2,1,1);imagesc(vidmovnew(1).cdata);colormap('gray');
while bpl == 1
bp1 = input('Bandpass start (px): ');
bp2 = input('Bandpass end (px): ');

bpnew = bpass(vidmovnew(1).cdata,bp1,bp2);

% Plot for visualization
subplot(2,1,2);
imshow(bpnew);
title(max(max(bpnew)));

bpl = input('Try another? (1 = yes; 0 = no) ');
end

% Use this bandpass filter on each frame and then find the peaks above a
% certain threshold. You can find what the peak should be from the title on
% the previous figure. You will then need to input an approximate diamter
% for this object.
% Finally, the particles are cleaned up by find the centroid. You can
% specify the locations of the local maxima and the area over which to
% average. Here we take half of the long lengthscale from the bandpass 
% plus 2.
% We then loop through multiple times so that you can define an appropriate
% set of thresholds, diameters, and centroid sizes. The output histogram is
% the x-position modulo 1, which should look flat if there are enough
% features and they are not pixel-based. Keep trying until you are happy.
tpk = 1;
while tpk == 1
pk1 = input('Threshold: ');
pk2 = input('Diameter: ');
ctrd = input('Centroid Diameter (REC:bp/2): ');
    vidmovnew(1).bp = bpass(vidmovnew(1).cdata,bp1,bp2);
    vidmovnew(1).pk = pkfnd(vidmovnew(1).bp,pk1,pk2);
    vidmovnew(1).cntrd = cntrd(vidmovnew(1).bp,vidmovnew(1).pk,ctrd);
figure(2);
hist(mod(vidmovnew(1).cntrd(:,1),1),20);
title(sprintf('%s %s','Number of features = ',num2str(length(vidmovnew(1).cntrd(:,1)))));

tpk = input('Repeat (1=yes;2=no)? ');
end

for i = 1:nFrames
    warning off
    vidmovnew(i).bp = bpass(vidmovnew(i).cdata,bp1,bp2);
    vidmovnew(i).pk = pkfnd(vidmovnew(i).bp,pk1,pk2);
    vidmovnew(i).cntrd = cntrd(vidmovnew(i).bp,vidmovnew(i).pk,ctrd);
end

% Now we can track the particles
for i = 1:nFrames
if isempty(vidmovnew(i).cntrd)==0 && isempty(vidmovnew(i).pk)==0
isempty0(i) = 1;
else
isempty0(i) = 0;
end
end
isempty01 = find(isempty0==1);

for i = 1:nFrames
    if isempty(vidmovnew(i).cntrd)==0 && isempty(vidmovnew(i).pk)==0
    poslist(i).x = vidmovnew(i).cntrd(:,1);
    poslist(i).y = vidmovnew(i).cntrd(:,2);
    poslist(i).brightness = vidmovnew(i).cntrd(:,3);
    poslist(i).radiusofgyration = vidmovnew(i).cntrd(:,4);
    poslist(i).time = tvec(i);
    numf(i) = length(vidmovnew(i).cntrd(:,1));
    else
    qm = findnearest(i,isempty01);m=isempty01(qm(1));
    poslist(i).x = vidmovnew(m).cntrd(:,1);
    poslist(i).y = vidmovnew(m).cntrd(:,2);
    poslist(i).brightness = vidmovnew(m).cntrd(:,3);
    poslist(i).radiusofgyration = vidmovnew(m).cntrd(:,4);
    poslist(i).time = tvec(m);
    numf(i) = length(vidmovnew(m).cntrd(:,1));
    end
end

NumFeatures = min(numf);

% Here each structure is a different particle, each column is the x,y, and
% time vector, and each row is a different point in time.
% We also do this for the radius of gyration and the brightness over time.
for i = 1:NumFeatures
    for j = 1:nFrames
    particles(i).posinput(j,:) = [poslist(j).x(i) poslist(j).y(i) tvec(j)];
    particles(i).brightness(j,:) = poslist(j).brightness(i);
    particles(i).radiusofgyration(j,:) = poslist(j).radiusofgyration(i); 
    end
end

m = 1;
for j = 1:nFrames
    for k = 1:length(poslist(j).x)
    particles2pos(m,1) = poslist(j).x(k);
    particles2pos(m,2) = poslist(j).y(k);
    particles2pos(m,3) = tvec(j);
    m = m+1;
    end
end

% Track the particles
trackthr = 500; % max disp
trparam.good = 100;
trparam.mem = 300;
trparam.dim = 2;
trackedparticles = track(particles2pos,trackthr,trparam);
numparticles = max(trackedparticles(:,4));
for j = 1:numparticles
    particletime(j) = length(find(trackedparticles(:,4)==j));
end
for j = 1:numparticles
    particledata{j} = trackedparticles(find(trackedparticles(:,4)==j),:);
end


%% Plot your data

% pick a particle
nparticle = 1;

% First, displacement in 2D
hf = figure(3);
imshow(vidmovnew(nparticle).cdata);colormap('gray');hold on;
set(hf, 'position', [150 150 vidWidth vidHeight])
plot(particles(nparticle).posinput(:,1),particles(nparticle).posinput(:,2));
axis([0 vidWidth 0 vidHeight]);
ylabel('Y Position');
xlabel('X Position');
title('position versus time in 2D');

% Displacement
figure(4);
subplot(3,1,1);
plot(tvec,particles(nparticle).posinput(:,1)); ylabel('x');
subplot(3,1,2);
plot(tvec,particles(nparticle).posinput(:,2)); ylabel('y');
subplot(3,1,3);
dsquared = particles(nparticle).posinput(:,1) + particles(nparticle).posinput(:,2);
plot(tvec,dsquared); ylabel('x+y');

% Find the vector length and angle, plot this over time
veclength = sqrt(particles(nparticle).posinput(:,1).^2 + particles(nparticle).posinput(:,2).^2);
vecangle = atan2d(particles(nparticle).posinput(:,1),particles(nparticle).posinput(:,2));
figure(5);
subplot(2,1,1)
plot(tvec,veclength);ylabel('vector length');
subplot(2,1,2);
plot(tvec,vecangle);ylabel('vector angle');


    
%% Make a movie
nparticle=1;
% Use this to create your own custom plots

% Try filtering? (1=yes 2=no)
filteryn = 1;
if filteryn ==1
    [particles(nparticle).posinputfiltered(:,1)]=hampel(tvec,particles(nparticle).posinput(:,1),10,50);
    [particles(nparticle).posinputfiltered(:,2)]=hampel(tvec,particles(nparticle).posinput(:,2),10,50);
else
    particles(nparticle).posinputfiltered(:,1)=particles(nparticle).posinput(:,1);
    particles(nparticle).posinputfiltered(:,2)=particles(nparticle).posinput(:,2);
end
veclength = sqrt(particles(nparticle).posinputfiltered(:,1).^2 + particles(nparticle).posinputfiltered(:,2).^2);

set(0,'DefaultFigureWindowStyle','default')
h2=figure;
subplot(2,1,2); plot(tvec,veclength,'k')
for i = 1:300
subplot(2,1,1)
imagesc(vidmovnew(i).cdata);colormap('gray');
hold on; scatter(particles(nparticle).posinputfiltered(i,1),particles(nparticle).posinputfiltered(i,2),'r.');
subplot(2,1,2);hold on;plot(tvec(1:i),veclength(1:i),'r');
h(i) = getframe(h2);
end

