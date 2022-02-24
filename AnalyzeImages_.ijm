// Run as Macro

#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File suffix", value = ".tif") suffix
#@ boolean (label = "Import channel info", value = false) chInfoCheckbox
#@ File (label = "Channel Info (optional)", style="open", value = "", required = false) chInfoFile

//input = "/Users/noahtjones/Dropbox (UFL)/Noah Notebook-Sweeney/Collaborations/Matt/Set 3/Myo6/12152021/cropped B4/cropped/test-input";
//output = "/Users/noahtjones/Dropbox (UFL)/Noah Notebook-Sweeney/Collaborations/Matt/Set 3/Myo6/12152021/cropped B4/test-output";
//suffix = ".tif";

// Dialog.create("Warning");
// Dialog.addMessage("This will go through all containing folders.\nIf the channels are inconsistent between images, then this program may not work properly.");
// Dialog.show();


function grabChannelsFromFoldersImage(input) { 
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i])) {
		grabChannelsFromFoldersImage(input + File.separator + list[i]);
		}
		if(endsWith(list[i], suffix)) {
	 		open(input + File.separator + list[i]);
			i = list.length;
   		}
	}
	Stack.getDimensions(width, height, channels, slices, frames);
	return newArray(channels, slices);
}

function myDialog(channels, slices) {
	DialogName = "Label channels and set thresholds";
	Dialog.create(DialogName);
	if (chInfoCheckbox == 1) {
		Table.open(chInfoFile);
		tableTitle = getTitle();
		theThresholds = Table.getColumn("Threshold");
		theNames = Table.getColumn("Name");
		theConvexHulls = Table.getColumn("Convex Hull");
		theParticles = Table.getColumn("Particles");
		theMinSizes = Table.getColumn("Min size");
		close(tableTitle);
	} else {
		theThresholds = newArray(241, 402, 323, 284, 0, 0, 0, 0, 0);
		theNames = newArray("nucleus", "phalloidin", "golgi", "reporter", "blank", "blank", "blank", "blank", "blank");
		theConvexHulls = newArray(false, false, false, false, false, false, false, false, false);
		theParticles = newArray(false, false, false, false, false, false, false, false, false);
		theMinSizes = newArray(0, 0, 0, 0, 0, 0, 0, 0, 0);
	}
	for (i = 1; i <= channels ; i++) {
		j = i - 1;
		Dialog.setInsets(0,20,0); //241 402 323 284 threshs
		Dialog.addMessage("Channel " + toString(i));
		Dialog.setInsets(5,20,0);
		Dialog.addString("Name", theNames[j], 20);
		Dialog.addSlider("Threshold", 0, slices*255, theThresholds[j]);
		Dialog.setInsets(0,20,0);
		Dialog.addCheckbox("Use for convex hull", theConvexHulls[j]);
		Dialog.addCheckbox("Use for analyze particles", theParticles[j]);
		Dialog.addString("Min particle size", theMinSizes[j], 5);
		if (i < channels) {
			Dialog.addMessage("\n");
		}
	}

	chinfotable = "Channel Info";
	Table.create(chinfotable);
	nameArray = newArray("Name", "Index", "Threshold", "Convex Hull", "Particles", "Min size");
	Dialog.show();

	for (i = 1; i <= channels ; i++) {
		nameCh = Dialog.getString();
		threshCh = Dialog.getNumber();
		cvxhllCh = Dialog.getCheckbox();
		ptcllCh = Dialog.getCheckbox();
		minPartSize = Dialog.getString();
		arrayCh = newArray(nameCh, i, threshCh, cvxhllCh, ptcllCh, minPartSize);
		stringCh = String.join(arrayCh, ",");
		List.set("Channel" + toString(i), stringCh);
		Table.update(chinfotable);
		len = lengthOf(arrayCh);
		for (j = 0; j < len; j++) {
			Table.set(nameArray[j], i-1, arrayCh[j]); // i-1
		}
		Table.update(chinfotable);
	}
	//ChannelMetadata = List.getList();
	Table.update(chinfotable);
	return chinfotable;
}

function checkFolder(input, channels) {
	list = getFileList(input);
	list = Array.sort(list);
	for (folderItem = 0; folderItem < list.length; folderItem++) {
		if(File.isDirectory(input + File.separator + list[folderItem])) {
			processFolder(input + File.separator + list[folderItem]);
		}
		if(endsWith(list[folderItem], suffix)) {
			open(input + File.separator + list[folderItem]);
			Stack.getDimensions(file_width, file_height, file_channels, file_slices, file_frames);
			if (file_channels != channels) {
				exit("wrong number of channels: " + input + File.separator + list[folderItem]);
			}
			close("*");
		}
	}
}

function processFolder(input, chinfotable) {
	list = getFileList(input);
	list = Array.sort(list);
	for (folderItem = 0; folderItem < list.length; folderItem++) {
		if(File.isDirectory(input + File.separator + list[folderItem])) {
			processFolder(input + File.separator + list[folderItem]);
		}
		if(endsWith(list[folderItem], suffix)) {
			processFile(input, output, list[folderItem], chinfotable);
		}
	}
}

function setUserSelection(us_xpoints, us_ypoints, us_name) {
	makeSelection("polygon", us_xpoints, us_ypoints);
	roiManager("add");
	nRoi = roiManager("count");
	nRoiMO = nRoi - 1;
	roiManager("select", nRoiMO);
	roiManager("rename", us_name);
}

function processFile(input, output, file, chinfotable) {
	numChnls = Table.size(chinfotable);
	open(input + File.separator + file);
	firstOpen = getTitle();
	print("Processing: " + input + File.separator + file);
	run("Crop");
	roiManager("add");
	roiManager("select", 0);
	Roi.getCoordinates(us_xpoints, us_ypoints);
	us_name = "user_selection";
	roiManager("rename", "user_selection");
	roiManager("deselect");
	run("Z Project...", "projection=[Sum Slices]");
	//run("8-bit");
	imageSum = getTitle();
	//close(firstOpen);
	run("Remove Outliers...", "radius=3 threshold=50 which=Bright"); 
	roiManager("select", "user_selection");
	run("Clear Outside");
	Roi.remove;
	for (chRow = 0; chRow < numChnls; chRow++) {
		// prepare
		chNum = chRow + 1;
		chName = Table.get("Name", chRow, chinfotable);
		
		// close original so only have sum
		// 241 402 323 284 threshs
		roiManager("reset");
		selectWindow(imageSum);
		Stack.getDimensions(width, height, sum_channels, slices, frames);
		
		// figure out how to get the sum of 
		// intensity values within the thresholded area
		// back to original
		
		run("Duplicate...", "channels=" + chNum + " duplicate");
		setUserSelection(us_xpoints, us_ypoints, us_name);
		roiManager("select", "user_selection");
		roiManager("Update");
		getStatistics(area, mean, min, max, std);
		chThresh = Table.get("Threshold", chRow, chinfotable);
		setThreshold(chThresh, max);
		
		run("Convert to Mask");
		theMask = getTitle();
		run("Despeckle");

		// Particles
		isForParticle = Table.get("Particles", chRow, chinfotable);
		mps = Table.get("Min size", chRow, chinfotable);
		if (isForParticle == 1) {
			run("Clear Results");
			selectWindow(theMask);
			run("Analyze Particles...", "size=" + mps + "-Infinity show=Outlines display exclude clear include summarize add in_situ");
			updateResults();
			roiManager("reset");
		
			//selectWindow(firstOpen);
			//setUserSelection(us_xpoints, us_ypoints, us_name);
	
			tableCurrentHeadings = String.getResultsHeadings;
			tHeads = split(tableCurrentHeadings);
			emptyArray = newArray();
			tableRefParticles = "analyze_particles-ch_" + chNum;
			
			// if there is no table, make one
			if (isOpen(tableRefParticles) == 0) {
				Table.create(tableRefParticles);
				for (tHeadsIndex = 1; tHeadsIndex < tHeads.length; tHeadsIndex++) {
					Table.setColumn(tHeads[tHeadsIndex], emptyArray, tableRefParticles);
				}
			} 
			Table.update(tableRefParticles);
			//selectWindow("analyze_particles-ch_" + chNum);
			tRows = Table.size("Results");
			for (row = 0; row < tRows; row++) {
				Table.update(tableRefParticles);
				colRefLen = Table.size(tableRefParticles);
				for (col = 0; col < tHeads.length; col++) {
					val = Table.get(tHeads[col], row, "Results");
					labels = Table.getColumn("Label", "Results");
					print("\n");
					print(tableRefParticles);
					print("Label: " + labels[row]);
					print("row: " + row);
					print("col: " + col + " (" + tHeads[col] + ")");
					print(val);
					if (col > 0) {
						Table.set(tHeads[col], colRefLen, val, tableRefParticles);
					} else { 
						Table.set("Label", colRefLen, labels[row], tableRefParticles);
					}
					Table.update(tableRefParticles);
				}
			}
		}
		
		// convex hull
		isForConvexHull = Table.get("Convex Hull", chRow, chinfotable);
		if (isForConvexHull == 1) {
			selectImage(theMask);
			Roi.remove;
			run("Create Selection");
			Roi.getContainedPoints(mask_xpoints, mask_ypoints);
			makeSelection("polygon", mask_xpoints, mask_ypoints);
			run("Convex Hull");
			Roi.setName("convex_hull");
			roiManager("add");
			selectWindow(imageSum);
			Roi.remove;
			roiManager("deselect");
			roiManager("select", "convex_hull");
			run("Clear Results");
			roiManager("multi-measure measure_all");
			Roi.remove;
			tableCurrentHeadings = String.getResultsHeadings;
			tHeads = split(tableCurrentHeadings);
			tableRefMM = "multi-measure-convex_hull-golgi-ch_" + chNum;
			if (isOpen(tableRefMM) == 0) {
				Table.create(tableRefMM);
				emptyArray = newArray();
				for (tHeadsIndex = 1; tHeadsIndex < tHeads.length; tHeadsIndex++) {
					if (tHeads[tHeadsIndex].contains("convex_hull")) {
						cHull = tHeads[tHeadsIndex];
						cHullIndex = cHull.indexOf("(convex_hull)");
						end = cHullIndex;
						tHeadMod = substring(tHeads[tHeadsIndex], 0, end);
					} else {
						tHeadMod = tHeads[tHeadsIndex];
					}
					Table.setColumn(tHeadMod, emptyArray, tableRefMM); //fixed
				}
			}
			tRows = nResults;
			colRefLen = Table.size(tableRefMM);
			for (row = 0; row < tRows; row++) {
				colRefLen = Table.size(tableRefMM);
				for (col = 0; col < tHeads.length; col++) {
					val = Table.get(tHeads[col], row, "Results");
					labels = Table.getColumn("Label", "Results");
					if (tHeads[col].contains("(convex_hull)")) {
						cHull = tHeads[col];
						cHullIndex = cHull.indexOf("(convex_hull)");
						end = cHullIndex;
						tHeadMod = substring(cHull, 0, end);
					} else {
						tHeadMod = tHeads[col];
					}
					print("\n");
					print(tableRefMM);
					print("Label: " + labels[row]);
					print("row: " + row);
					print("col: " + col + " (" + tHeads[col] + " or " + tHeadMod + ")");
					print(val);
					if (col > 0) {
						Table.set(tHeadMod, colRefLen, val, tableRefMM);
					} else { 
						Table.set("Label", colRefLen, labels[row], tableRefMM);
					}
				}
			}
			
			Table.update(tableRefMM);
			
			// mark up and save image for reference
			selectWindow(imageSum);
			run("Duplicate...", "duplicate");
			run("Line Width...", "line=1");
			run("Colors...", "foreground=white background=black selection=yellow");
			run("RGB Color", "Keep Source Stacks=0");
			roiManager("select", "convex_hull");
			run("Draw", "slice");
			saveAs("PNG", output + File.separator + file + "-" + "ch_" + chNum);
			close("*.png");
		}
		
		run("Clear Results");
		close(theMask);
	}
	// clean up
	close(imageSum);
	close("*.tif");
	roiManager("reset");

	//return newArray(tableRefMM, tableRefParticles);
}

// get info from user
roiManager("reset");
gCFFIout = grabChannelsFromFoldersImage(input);
channels = gCFFIout[0];
slices = gCFFIout[1];
chinfotable = myDialog(channels, slices);

// setup
setOption("BlackBackground", true);
run("Set Measurements...", "area mean standard modal min centroid center perimeter bounding fit shape feret's integrated median skewness kurtosis area_fraction stack display redirect=None decimal=3");

// go!!!
checkFolder(input, channels);
processFolder(input, chinfotable);

a = getList("window.titles");
b = lengthOf(a);
for (i = 0; i < b; i++) {
	c = a[i];
	d = indexOf(c, "ch_");
	if (d != -1) {
		selectWindow(c);
		ttit = Table.title;
		Table.save(output + File.separator + ttit + ".csv");
	}

}
selectWindow("Channel Info");
Table.save(output + File.separator + "channel_info" + ".csv");