//============================================================
// QUANTIFICATION of Ksp37 in cells
// - Segments cells on channel 0
// - Filters to Ksp37+ cells only (channel 1 mean signal > threshold)
// - Saves a table with the percentage of Ksp37+ cells and mean 
//	 fluorescence intensity in the positive cells
// - Saves a JPEG outline of positive and negative cells
//============================================================

//---------------- USER PARAMETERS ----------------
bgRolling1            = 8;     // rolling ball radius, channel 1 (Ksp37)
signalThreshold_Ksp37 = 13;     // mean Ksp37 signal above which a cell counts as "positive"
colorPositive         = "orange";
colorNegative         = "cyan";
displayMin            = 40;     // display range of the Ksp37 image in the JPEG
displayMax            = 120;
fileExtension         = ".nd2"; // file type to process in the input folder
//---------------------------------------------------

// preparation and folder selection
inputDir = getDirectory("Choose the folder with your images");
mainOutputDir = getDirectory("Choose your output folder");

subFolder = mainOutputDir + "Segmentation" + File.separator;

fullTablePath = mainOutputDir + "Ksp37_Results.csv";
masterTable = "Ksp37_Results";

if (isOpen(masterTable)) {
selectWindow(masterTable);
} else if (File.exists(fullTablePath)) {
open(fullTablePath);
Table.rename(File.getName(fullTablePath), masterTable);
} else {
Table.create(masterTable);
}

if (!File.exists(subFolder)) File.makeDirectory(subFolder);

// Collect the image files in the input folder
allFiles = getFileList(inputDir);
files = newArray(0);
for (k = 0; k < allFiles.length; k++) {
	if (endsWith(toLowerCase(allFiles[k]), toLowerCase(fileExtension))) {
		files = Array.concat(files, allFiles[k]);
	}
}
if (files.length == 0) {
	exit("No " + fileExtension + " files found in " + inputDir);
}

print("\\Clear");
run("Close All");
setBatchMode(true);

// ---------------- LOOP OVER ALL IMAGES ----------------
for (f = 0; f < files.length; f++) {

	print("=== Image " + (f+1) + " / " + files.length + ": " + files[f] + " ===");

	// Open the image, one window per channel (titles end in "C=0", "C=1")
	run("Bio-Formats Importer", "open=[" + inputDir + files[f] + "] autoscale color_mode=Default split_channels view=Hyperstack stack_order=XYCZT");

	// Identify window names
	title0 = ""; // Cell mask image
	title1 = ""; // AF488 image, Ksp37 antibody

	list = getList("image.titles");
		for (i=0; i<list.length; i++) {
			if (endsWith(list[i], "C=0")) {
				title0 = list[i];
				}
				if (endsWith(list[i], "C=1")) {
					title1 = list[i];
					}
		}

	if (title0 == "" || title1 == "") {
		print("Skipped " + files[f] + ": channel windows C=0 / C=1 not found.");
	} else {

	// Image name used in the table and the JPEG file name
	baseName = replace(title1, " - C=1", "");
	baseName = replace(baseName, "C=1", "");

	// Start from blank
	roiManager("reset");
	run("Clear Results");
	run("Collect Garbage");

	// 1. Subtract Background for all channels
	selectWindow(title0);
	run("Subtract Background...", "rolling=60 separate");
	selectWindow(title1);
	run("Subtract Background...", "rolling="+bgRolling1+" separate");

	// 2. Create mask of membrane stain
	selectWindow(title0);
	run("Duplicate...", "title=maskCells");
	selectWindow("maskCells");
	run("Gaussian Blur...", "sigma=2");
	setAutoThreshold("Huang dark");
	setOption("BlackBackground", true);
	run("Convert to Mask");

	// 3. Analyze particles to create ROI
	run("Analyze Particles...", "size=20-Infinity include add");
	selectWindow("maskCells");
	setForegroundColor(255, 255, 255);
	roiManager("Fill");

	nAllCells = roiManager("count");
	print("Detected cells: " + nAllCells);
	if (nAllCells == 0) {
		print("Skipped " + baseName + ": no cells detected - check thresholding.");
	} else {

	// 4. Identify Ksp37+ cells
	selectWindow(title1);
	cellMeans  = newArray(nAllCells);
	posIndices = newArray(0);
	negIndices = newArray(0);
	sumPos = 0;

	for (i = 0; i < nAllCells; i++) {
		roiManager("select", i);
		getStatistics(area, meanVal);
		cellMeans[i] = meanVal;
		if (meanVal > signalThreshold_Ksp37) {
			posIndices = Array.concat(posIndices, i);
			sumPos += meanVal;
		} else {
			negIndices = Array.concat(negIndices, i);
		}
	}
	roiManager("deselect");

	nPositive   = posIndices.length;
	nNegative   = negIndices.length;
	pctPositive = 100 * nPositive / nAllCells;
	if (nPositive > 0) meanPos = sumPos / nPositive;
	else meanPos = NaN;

	print("Positive cells: " + nPositive + " / " + nAllCells);
	print("Percent positive: " + d2s(pctPositive, 1) + " %");
	print("Mean Ksp37 intensity of positive cells: " + d2s(meanPos, 2));

	// 5. Save results to table (overwrites the row if this image was analysed before)
	row = -1;
	nRows = Table.size(masterTable);
	if (nRows > 0 && Table.columnExists("Image_Name", masterTable)) {
		for (r = 0; r < nRows; r++) {
			if (Table.getString("Image_Name", r, masterTable) == baseName) {
				row = r;
				r = nRows; // stop searching
			}
		}
	}
	if (row == -1) row = nRows;

	Table.set("Image_Name", row, baseName, masterTable);
	Table.set("N_cells", row, nAllCells, masterTable);
	Table.set("N_Ksp37_positive", row, nPositive, masterTable);
	Table.set("Pct_Ksp37_positive", row, pctPositive, masterTable);
	Table.set("Mean_Ksp37_intensity_positive", row, meanPos, masterTable);
	Table.set("bgRolling1", row, bgRolling1, masterTable);
	Table.set("signalThreshold_Ksp37", row, signalThreshold_Ksp37, masterTable);
	Table.set("displayMin", row, displayMin, masterTable);
	Table.set("displayMax", row, displayMax, masterTable);
	Table.update(masterTable);
	Table.save(fullTablePath, masterTable);

	// 6. Create staining image with cell outlines
	selectWindow(title1);
	run("Grays");
	run("Green");
	setMinAndMax(displayMin, displayMax);
	roiManager("Set Line Width", 1);

	if (nPositive > 0) {
		roiManager("select", posIndices);
		roiManager("Set Color", colorPositive);
	}
	if (nNegative > 0) {
		roiManager("select", negIndices);
		roiManager("Set Color", colorNegative);
	}
	roiManager("deselect");

	run("From ROI Manager");   // put ROIs on the image as an overlay
	Overlay.drawLabels(false);
	roiManager("show all without labels");
	run("Scale Bar...", "width=20 height=10 font=32 horizontal bold color=White background=None location=[Lower Right] overlay");
	run("Flatten");
	saveAs("Jpeg", subFolder + baseName + "_Ksp37_outlines.jpg");

	} // end of "cells detected"
	} // end of "channels found"

	// 7. Clean up before the next image
	roiManager("reset");
	run("Close All"); 

	if (isOpen("Results")) {
	selectWindow("Results");
	run("Close");
	}
}

setBatchMode(false);
print("Done. Processed " + files.length + " file(s).");