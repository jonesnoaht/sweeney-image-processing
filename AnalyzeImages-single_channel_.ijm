// Run as Macro

//#@ File (label = "Input directory", style = "directory") input
//#@ File (label = "Output directory", style = "directory") output
//#@ String (label = "File suffix", value = ".tif") suffix

input = "/Users/noahtjones/Dropbox (UFL)/Noah Notebook-Sweeney/Collaborations/Matt/Set 3/Myo6/12152021/cropped B4/cropped/test";
output = "/Users/noahtjones/Dropbox (UFL)/Noah Notebook-Sweeney/Collaborations/Matt/Set 3/Myo6/12152021/cropped B4/output v10";
suffix = ".tif";

// Dialog.create("Warning");
// Dialog.addMessage("This will go through all containing folders.\nIf the channels are inconsistent between images, then this program may not work properly.");
// Dialog.show();

//showMessage("Success!","Got past the dialog.");

function grabChannelsFromFoldersImage(input) { 
    list = getFileList(input);
    list = Array.sort(list);
    for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]))
	    grabChannelsFromFolderesImage(input + File.separator + list[i]);
		if(endsWith(list[i], suffix)) {
			//var1 = list[i];
			//var2 = input + File.separator + list[i];
			//print(var2);
	 		open(input + File.separator + list[i]);
			i = list.length;
   		}
    }
    Stack.getDimensions(width, height, channels, slices, frames);
    return channels; // idk if this will work
}

//showMessage("Success!","Defined first function.");

function myDialog(channels) {
    DialogName = "Label channels and set thresholds";
    Dialog.create(DialogName);
    for (i = 1; i <= channels ; i++) {
	Dialog.setInsets(0,20,0);
	Dialog.addMessage("Channel " + toString(i));
	Dialog.setInsets(5,20,0);
	Dialog.addString("Name", "marker", 20);
	slices = nSlices;
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
    //ChannelMetadata = List.getList();
    return chinfotable;
}

channels = grabChannelsFromFoldersImage(input);

print(channels);

//showMessage("Success!","I think. Channels = " + channels);

chinfotable = myDialog(channels);

//ChannelMetadata

// Manually Selected Thresholds
// (if zero then run auto-threshold)
// setup

setOption("BlackBackground", true);
run("Set Measurements...", "area mean standard modal min centroid center perimeter bounding fit shape feret's integrated median skewness kurtosis area_fraction stack limit display add redirect=None decimal=3");

//myFolder = getInfo("image.directory");
//myFile = getInfo("image.filename");

//Table.create("multi-measure-convex_hull-golgi");
//tableRefMM = "multi-measure-convex_hull-golgi"; // not needed?

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

//showMessage("line 109");

function processFile(input, output, file, chinfotable) {
    print("Processing: " + input + File.separator + file);
    open(input + File.separator + file);
    run("Crop");
    roiManager("add");
    run("Z Project...", "projection=[Sum Slices]");
    run("Remove Outliers...", "radius=3 threshold=50 which=Bright"); 
    // no need to repeat
    selectImage(1);
    close();
    selectImage(1);
    myImage = getTitle();
    roiManager("select", 0);
    run("Make Inverse");
    run("Set...", "value=0");
    roiManager("select", 0);
	//showMessage("line 126");
    // figure out how to get the sum of 
    // intensity values within the thresholded area
    // back to original
    roiManager("select", 0);
    run("Duplicate...", "channels=3 duplicate"); // LOOK HERE TO CHANGE CHANNEL
    myDuplicate = getTitle();
    getStatistics(area, mean, min, max, std);
    chThresh = Table.get("Threshold", 3, chinfotable); // needs update
    setThreshold(chThresh, max);
    //threshImageId = getImageID();
    threshImageTitle = getTitle();
    run("Convert to Mask");
    run("Despeckle");
    run("Duplicate...", "duplicate");
    dupImageTitle = getTitle();
    run("Analyze Particles...", "size=0-Infinity show=Outlines display exclude clear include summarize add in_situ");
    //showMessage("line 144");
    // START not yet tested
    tableCurrent = "Results";
    //showMessage("Current table: " + tableCurrent);
    tableCurrentHeadings = Table.headings(tableCurrent);
    tHeads = split(tableCurrentHeadings);
	emptyArray = newArray();
    tableRefParticles = "analyze_particles";
    if (isOpen(tableRefParticles) == 0) {
		Table.create(tableRefParticles);
		for (tHeadsIndex = 1; tHeadsIndex < tHeads.length; tHeadsIndex++) {
			Table.setColumn(tHeads[tHeadsIndex], emptyArray, tableRefParticles);
		}
    }
    tRows = Table.size(tableCurrent);
    for (row = 0; row < tRows; row++) {
    	colRefLen = Table.size(tableRefParticles);
    	for (col = 0; col < tHeads.length; col++) {
    		val = Table.get(tHeads[col], row, tableCurrent);
    		//label = "fuck";
    		labels = Table.getColumn("Label", tableCurrent);
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
  	  }
    }
    Table.update(tableRefParticles);
    close(tableCurrent);
    //run("Clear Results");
    close(dupImageTitle);
    selectImage(threshImageTitle);
    run("Create Selection");
    Roi.getContainedPoints(xpoints, ypoints);
    makeSelection("polygon", xpoints, ypoints);
    roiManager("Deselect");
    roiManager("Delete");
    run("Convex Hull");
    Roi.setName("convex_hull");
    roiManager("add");
    //roiManager("measure");
    //run("Clear Results");
    //showMessage("Woahhhhh","what are we about to close?");
    close(threshImageTitle);
    selectWindow(myImage);
    roiManager("select", "convex_hull");
    roiManager("multi-measure one");
    tableCurrent = "Results";
    tableCurrentHeadings = Table.headings(tableCurrent);
    tHeads = split(tableCurrentHeadings);
    tableRefMM = "multi-measure-convex_hull-golgi";
    //showMessage("line 197");
    if (isOpen(tableRefMM) == 0) {
		Table.create(tableRefMM);
		tHeads = split(tableCurrentHeadings);
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
    //showMessage("line 210");
    tRows = Table.size(tableCurrent);
    colRefLen = Table.size(tableRefMM);
    for (row = 0; row < tRows; row++) {
    	colRefLen = Table.size(tableRefMM);
    	for (col = 0; col < tHeads.length; col++) {
    		val = Table.get(tHeads[col], row, tableCurrent);
    		labels = Table.getColumn("Label", tableCurrent);
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
    //showMessage("line 225");
    close(tableCurrent); // uncomment this
    run("Colors...", "foreground=black background=black selection=yellow");
    run("Line Width...", "line=1");
    run("RGB Color", "Keep Source Staks=0");
    roiManager("select", "convex_hull");
    run("Draw", "slice");
    run("Colors...", "foreground=white background=black selection=yellow");

    close(myImage);

    // save(myFolder+myFile+"-marked_ROI.png"); // not needed for Batch
    // close(); // not needed for Batch

    roiManager("Deselect");
    roiManager("Delete");

    print("Saving to: " + output);
    close("*");

    return newArray(tableRefMM, tableRefParticles);
}

//showMessage("line 141");

close("*");
processFolder(input, chinfotable);

//selectWindow("multi-measure-convex_hull-golgi");
//Table.save(output + File.separator + "multi-measure-convex_hull-golgi.csv");
//selectWindow("analyze_particles");
//Table.save(output + File.separator + "analyze_particles.csv");

// need to do for multiple channels
// first, go through the channels and set the threshold for each channel


