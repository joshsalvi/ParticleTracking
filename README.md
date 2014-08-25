ParticleTracking
================

MATLAB particle tracking

bpass is a spatial bandpass filter which smooths the image and subtracts the background off. The two numbers are the spatial wavelength cutoffs in pixels. The first one is almost always '1'. The second number should be something like the diameter of the 'blob's you want to find in pixels. Try a few values and use the one that gives you nice, sharply peaked circular blobs where your particles were; remember the numbers you used for bpass.
