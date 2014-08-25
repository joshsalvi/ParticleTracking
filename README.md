ParticleTracking
================

MATLAB particle tracking

bpass is a spatial bandpass filter which smooths the image and subtracts the background off. The two numbers are the spatial wavelength cutoffs in pixels. The first one is almost always '1'. The second number should be something like the diameter of the 'blob's you want to find in pixels. Try a few values and use the one that gives you nice, sharply peaked circular blobs where your particles were; remember the numbers you used for bpass.

b = bpass(a,1,10);

The next step is to identify the blobs that bpass has found as features. You will want to first use the pkfnd macro. If you have noisy data, read the preamble in pkfnd. As with all of this code, make sure that you read the complete documentation.

pk = pkfnd(b,60,11);

First thing you should do is read the documentation on track. It is essential that you put your position list in the required format. Once you have that, you are in the clear. Just invoke track with the parameters that are right for you and you should be fine. 

tr = track(pos_lst, 3);

Here, pos_lst is the list of particle positions and the timestamp for each frame to be considered concatenated vertically.
