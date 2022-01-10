// Run as Macro

#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File suffix", value = ".tif") suffix

Dialog.create("Warning");
Dialog.addMessage("This will go through all containing folders.\n If the channels are inconsistent between images, then this program may not work properly.");
Dialog.show();

function grabChannelsFromFolderesImage(input) { 
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]))
			processFolder(input + File.separator + list[i]);
		if(endsWith(list[i], suffix))
			File.open(input + File.separator + list[i]);
			i = list.length;
	}
}

function myDialog(channels) {
	DialogName = "Label channels and set thresholds";
	Dialog.create(DialogName);
	for (i = 1; i <= channels ; i++) {
		Dialog.setInsets(0,20,0);
		Dialog.addMessage("Channel " + toString(i));
		Dialog.setInsets(5,20,0);
		Dialog.addString("Name", "marker", 20);
		Dialog.addSlider("Threshold", 0, slices*255, 180);
		Dialog.setInsets(0,20,0);
		Dialog.addCheckbox("Use for convex hull", false);
		if (i < channels) {
			Dialog.addMessage("\n");
		}
	}

	chinfotable = "Channel Info";
	Table.create(chinfotable);
	nameArray = newArray("Name", "Index", "Threshold", "Convex Hull");
	Dialog.show();

	for (i = 1; i <= channels ; i++) {
		nameCh = Dialog.getString();
		threshCh = Dialog.getNumber();
		cvxhllCh = Dialog.getCheckbox();
		arrayCh = newArray(nameCh, i, threshCh, cvxhllCh);
		stringCh = String.join(arrayCh, ",");
		List.set("Channel" + toString(i), stringCh);
		Table.update(chinfotable);
		for (j = 0; j < 4; j++) {
			Table.set(nameArray[j], i-1, arrayCh[j]);
		}
	}
	ChannelMetadata = List.getList();
	return ChannelMetadata;
}

Stack.getDimensions(width, height, channels, slices, frames);

	ChannelMetadata = List.getList();
	return ChannelMetadata;
}

Stack.getDimensions(width, height, channels, slices, frames);

grabChannelsFromFolderesImage(input);

myDialog(channels);

// Manually Selected Thresholds
// (if zero then run auto-threshold)
// setup

setOption("BlackBackground", true);
run("Set Measurements...", "area mean standard modal min centroid center perimeter bounding fit shape feret's integrated median skewness kurtosis area_fraction stack limit display add redirect=None decimal=3");

myFolder = getInfo("image.directory");
myFile = getInfo("image.filename");

Table.create("multi-measure-convex_hull-golgi");
Table.create("analyze_particles");

function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]))
			processFolder(input + File.separator + list[i]);
		if(endsWith(list[i], suffix))
			processFile(input, output, list[i]);
	}
}

function processFile(input, output, file) {
	print("Processing: " + input + File.separator + file);
	print("Saving to: " + output);
	run("Crop");
	roiManager("add");
	run("Z Project...", "projection=[Sum Slices]");
	run("Remove Outliers...", "radius=3 threshold=50 which=Bright"); // no need to repeat
	selectImage(1);
	close();
	selectImage(1);
	myImage = getTitle();
	roiManager("select", 0);
	run("Make Inverse");
run("Set...", "value=0");
roiManager("select", 0);

// figure out how to get the sum of intensity values within the thresholded area

// back to original
// 

roiManager("select", 0);
run("Duplicate...", "channels=3 duplicate"); // LOOK HERE TO CHANGE CHANNEL
myDuplicate = getTitle();
getStatistics(area, mean, min, max, std);
setThreshold(channel3Threshold, max); // AND **ESPECIALLY** HERE
run("Convert to Mask");
run("Despeckle");
run("Duplicate...", "duplicate");
run("Analyze Particles...", "size=0-Infinity show=Outlines display exclude clear include summarize add in_situ");
Table.save(myFolder + myFile + "analyze_particles-table.csv");
tabletitle = Table.title;
close(tabletitle);
run("Clear Results");
close();
run("Create Selection");
Roi.getContainedPoints(xpoints, ypoints);
makeSelection("polygon", xpoints, ypoints);
roiManager("Deselect");
roiManager("Delete");
run("Convex Hull");
roiManager("add");
Roi.setName("convex_hull");
roiManager("measure");
run("Clear Results");
close();
selectWindow(myImage);
roiManager("select", "convex_hull");
roiManager("Multi Measure");
saveAs("Results", myFolder + myFile + "-multi-measure-convex_hull-golgi.csv");
run("Clear Results");
roiManager("select", 0);
run("Colors...", "foreground=black background=black selection=yellow");
run("Line Width...", "line=1");
run("RGB Color");
roiManager("select", "convex_hull");
run("Draw", "slice");
run("Colors...", "foreground=white background=black selection=yellow");

selectWindow(myImage);
close();

// save(myFolder+myFile+"-marked_ROI.png"); // not needed for Batch
// close(); // not needed for Batch

roiManager("Deselect");
roiManager("Delete");
}


// need to do for multiple channels
// first, go through the channels and set the threshold for each channel


