run("Close All");
/* 
 *  Welcome to FluorMask3D 
 *  
 *  This program was designed to analyse multichannel images and automatically create binary masks, 
 *  overlay them in the fluorescence channels and measure the intensity values of different markers 
 *  in a specific region, all with 3D data. Example of data was done in Eukaryotic cells spheroids in 3D
 *  
 *  Created: 23rd of June 2025 by Dr Laia Pasquina-Lemonche, University of Sheffield (cc)
 */

dir1 = getDirectory("Select the folder containing images");
open();
name1 = File.nameWithoutExtension;

//Ask the user what type of image this is (we will get the "region" corresponding to Cancer from the Green image, but we need to analyse the others too)
ImageType = newArray("GREEN", "PINK", "BLUE", "YELLOW");
Treated = false;

Dialog.create("Selection of the colour fo the dye in your image");
Dialog.addMessage("The workflow works by first analysing the Green image to find the Cancer Region, \n then the rest of the images. If you did not select the GREEN image first, then select Cancel and run the code again.");
Dialog.addChoice("Select Colour of your dye (choose between GREEN, RED, BLUE or YELLOW) :",ImageType);
Dialog.addCheckbox("Are the cancer cells treated?", Treated);

Dialog.show();
ImageType = Dialog.getChoice();
Treated = Dialog.getCheckbox();

dir2 = dir1 + name1 + "_Results" + File.separator;
File.makeDirectory(dir2);

//Rename image so this is useful for any image
rename("Original_w_background");

//make sure the measurements are not directed into any other image (due to the code having run before)
run("Set Measurements...", "area mean standard modal min centroid center perimeter integrated display redirect=None decimal=2");

//Do the same for the last slice
selectImage("Original_w_background");
slices = nSlices();
run("Duplicate...", "duplicate range="+slices+"-"+slices);
run("Measure"); // Measure on the last slice
Mean_last = getResult("Mean", 0); //gets the mean value from the first row
run("Clear Results");

//Calculate the average background value to be able to mathematically substract the background noise
//Average_background = (Mean_1+Mean_last)/2;
Average_background = Mean_last;
//saveAs("Results", "C:/Users/bi1lp/Desktop/testing_workflow/Results_first_and_last_slice.csv");
selectImage("Original_w_background");
run("Subtract...", "value="+Average_background+" stack");
//get the 2 mean values and do an average

//Change scale to make it more manageable to do the masks later
run("Scale...", "x=- y=- z=1.0 width=728 height=728 depth=70 interpolation=Bilinear average process create");
rename("Original");

//selectImage("Original_w_background");
run("Clear Results");

selectImage("Original");
run("Duplicate...", "duplicate");
slices = nSlices();

selectImage("Original-1");
//Do filters on the image
run("Gaussian Blur...", "sigma=2 stack");
run("Mean...", "radius=2 stack");

//Do automatic threshold Otsu
run("8-bit");

//The treated cancer is less tall so we need to do thresholding at the beggining of the stack rather than the middle
if(Treated == false){
	setSlice(slices/2);
}
if(Treated == true){
	setSlice(slices/4);
}
setAutoThreshold("Otsu dark no-reset");
setOption("BlackBackground", true);
run("Convert to Mask", "method=Otsu background=Dark black");

//Filter a bit the binary stack to avoid measuring most of just empty space
run("Close-", "stack");
run("Fill Holes", "stack");

selectImage("Original-1");
run("Duplicate...", "duplicate");
rename("mask");

//Save the mask of all the image
selectImage("Original-1");
saveAs("Tiff", dir2+"MASK_to_crop.tif");
//saveAs("Tiff", "C:/Users/bi1lp/Desktop/testing_workflow/MASK_to_crop.tif");
selectImage("MASK_to_crop.tif");
rename("MASK_to_crop");


//Now do the measurements but not on the masked image, but to the original image
selectImage("mask");
run("Set Measurements...", "area mean standard modal min centroid center perimeter integrated display redirect=Original decimal=2");
run("Analyze Particles...", "size=50-Infinity show=Outlines display include summarize add stack");

selectImage("Drawing of mask");
saveAs("Tiff", dir2+"Drawing of mask.tif");
//saveAs("Tiff", "C:/Users/bi1lp/Desktop/testing_workflow/Drawing of mask.tif");


//define variables and get values from results
num_slices = newArray(slices);
Total_area = newArray(slices);
selectWindow("Summary of mask");
Table.rename("Summary of mask", "Summary");


selectWindow("Summary");
Total_area = Table.getColumn("Total Area"); //- Returns the specified column as an array.

//Cleaning the array from NaN values and substituting them by 0 - saving summary table
for (i = 0; i < slices; i++) {
if(Total_area[i] == NaN){
			Total_area [i] = 0;
		}
}

if(ImageType == "GREEN"){
saveAs("Results", dir2+"Table_used_to_find_Cancer_Region.csv");
Table.rename("Table_used_to_find_Cancer_Region.csv", "Summary");
//saveAs("Results", "C:/Users/bi1lp/Desktop/testing_workflow/Summary.csv");
}

//saving results table
selectWindow("Results");
saveAs("Results", dir2+"Raw_Results_of_all_slices.csv");
//saveAs("Results", "C:/Users/bi1lp/Desktop/testing_workflow/Results_all_of Original.csv");
    
    run("Clear Results");
	//run("Close All");
	
	selectWindow("Summary");
	run("Clear Results");
	close("Summary");
	close("Results");
	
	  if (roiManager("count")>0) {
			roiManager("Deselect");
			roiManager("Delete");
		}

//Do data fitting to find the slices wehre the Cancer region is
xValues = num_slices; // I don't think I need this and actually this is now an empty array
yValues = Total_area;

macro "Fit Double Logistic" {
   
   // n = xValues.length;
    n = slices;

   // n = xValues.length;
    if (n == 0) {
    	print("exit(No data found in file.)");
    }
    
 // Find the maximum value manually (since max() does not exist in FIJI)
    maxY = yValues[0];
    for (i = 1; i < n; i++) {
        if (yValues[i] > maxY) {
            maxY = yValues[i];
        }
    }

	//Apply 30% threshold
	threshold = 0.3 * maxY; // 30% of max as threshold
    firstIndex = 0;
    lastIndex = 0;

    for (i = 0; i < n; i++) {
        if (yValues[i] > threshold) {
            firstIndex = i;
            i = n;
        }
    }
    k=n-1;
    for (k = n - 1; k >= 0; k--) {
        if (yValues[k] > threshold) {
            lastIndex = k;
            k=0;
        }
    }


     // Get actual slice numbers (all of this does not work I think)
    firstSlice = xValues[firstIndex];
    lastSlice = xValues[lastIndex];
    croppedRegionSize = abs(lastSlice-firstSlice);
    cropped_regionX = newArray(croppedRegionSize);
    cropped_regionY = newArray(croppedRegionSize);
    
    for(j=0; j < croppedRegionSize; j++){
    	cropped_regionX[j]=xValues[(firstSlice-1)+j];
    	cropped_regionY[j]=yValues[(firstSlice-1)+j];	
    }
    
    if(ImageType != "GREEN"){
    //Create if/else about the colour of the image
    //Input size length of images (nm). All must be the same - can be made to accept a .txt file if requested. Lengths then converted to pixels
		Dialog.create("Dimensions");
		Dialog.addNumber("Cancer region (from GREEN) first slice cut-off:", 6);
		Dialog.addNumber("Cancer region (from GREEN) Last slice cut-off:", 43);
		Dialog.show();
		firstIndex = Dialog.getNumber();
		lastIndex = Dialog.getNumber();
    }
    print("Image type: "+ImageType);
    print("Cancer region is between: Slice " + firstIndex + " and Slice " + lastIndex); //Final results
 
    
    //cropped the mask and the original based on the limits that we found where the cancer region is.
	selectImage("MASK_to_crop");
	run("Duplicate...", "duplicate range="+firstIndex+"-"+lastIndex+" use");
	saveAs("Tiff", dir2+"CroppedMask.tif");
	//saveAs("Tiff", "C:/Users/bi1lp/Desktop/testing_workflow/CroppedMask.tif");
	rename("CroppedMask");
	
	selectImage("Original");
	run("Duplicate...", "duplicate range="+firstIndex+"-"+lastIndex+" use");
	rename("Original_cropped");

	
	//Analyse cropped data again but this time we will save the results as "cropped results"
	selectImage("CroppedMask");
	run("Set Measurements...", "area mean standard modal min centroid center perimeter integrated display redirect=Original_cropped decimal=2");
    run("Analyze Particles...", "size=50-Infinity show=Outlines display include summarize add stack");
    
    number_of_rois = roiManager("count");
    
    //define variables and get values from results
	Sum_of_Mean = 0;
	Mean = newArray(number_of_rois);
	selectWindow("Results");
	
	for (k = 0; k < number_of_rois; k++) {
				Mean [k] = getResult("Mean", k);
	}

    //Calculating the sum of all the mean values / Which is what we need for the analysis
    for (i = 0; i < number_of_rois; i++) {
    	
	Sum_of_Mean = Sum_of_Mean + Mean[i];
		
    }
    
    //Saving the results from the cropped region
    saveAs("Results", dir2+"Filtered_Results.csv");
	//saveAs("Results", "C:/Users/bi1lp/Desktop/testing_workflow/Results_from_croppedOriginal.csv");
	print("Sum_of_mean intensity from Cancer region from"+ImageType+" image = "+Sum_of_Mean);
	
	selectImage("Original_cropped");
	run("From ROI Manager"); //do overlay
	saveAs("Tiff", dir2+"Original_Overlay_with_analysed_data.tif");
	//saveAs("Tiff", "C:/Users/bi1lp/Desktop/testing_workflow/Original_Overlay_with_analysed_data.tif");
	
	//Close Everything
	run("Clear Results");
	selectWindow("Summary of CroppedMask");
	run("Clear Results");
	close("Summary of CroppedMask");
	close("Results");
	


    if (roiManager("count")>0) {
			roiManager("Deselect");
			roiManager("Delete");
		}
	close("ROI Manager");
	run("Close All");

}