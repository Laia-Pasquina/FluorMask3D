# FluorMask3D
FluorMask3D was designed to analyse multichannel images and automatically create binary masks, overlay them in the fluorescence channels and measure the intensity values of different markers in a specific region, all with 3D data. Example of data was done in Eukaryotic cells spheroids in 3D

![Image](https://github.com/user-attachments/assets/483257d7-adf8-4e61-822f-c670bf33021f)

This is what the program does: 

– Image analysis “FluorMask3D” workflow description. (i) First the background was measured from slide 0 and subtracted from the Green channel corresponding to the Cancer spheroid labelled with CellTracker CMFDA probes. The, the corrected image was filtered with a Gaussian Blur and a reduction of pixels to 728x728 was prerformed; (ii) Then a binary mask was made for the whole stack (e.g. 70 slices) of the image (white = 255, black = 0); (iii) This mask was then overlayed on the fluorescence image (background corrected) to calculate the total area of the mask and its intensity signal for each slice; (iv) To find the region corresponding only to the cancer spheroid, the total area from each slice was plotted against the slices. This graph generally follows an asymmetric double sigmoid function. The steeper points on each side represent the beginning and end of the cancer spheroid, they were found by the FIJI macro and these slides (e.g. 6-61) are designated as the cancer region. (iv) The steps (i)-(iii) were repeated with the cleaved Caspase 3 yellow channel and with the cyan nuclei. Once the mask was created, it was cropped using the cancer region slides (e.g. 6-61) then in this region the mean fluorescence for the masked area in each slice was measured and then summed together to produce the fluorescence value for each channel. The ratio of Yellow/Cyan was calculated as the relative fluorescence of the cleaved caspase 3 indicating death of cells within the cancer spheroid. -

# Step-by-step

1. Download and open FIJI following instructions here: https://imagej.net/downloads
2. Make sure your images are in .tiff format as stacks and different channels (if your images are in a proprietry software from the microscope, open them in FIJI and follow instructions from BioFormats which should pop-up as soon as it recognsies your current format).
3. Download FIJI macro named "FluorMask3D" and drage it into FIJI
4. Click Run and follow instructions in the log windows
5. Contact me if you have any questions.
