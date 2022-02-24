#@ File (label = "Input directory", style = "directory") in1
#@ File (label = "Output directory", style = "directory") out1
#@ String (label = "File suffix", value = ".tif") suffix

from ij import IJ
import os
import ij.gui
import ij.io
import ij.plugin

def grabChannelsFromFoldersImage(in1): 
	l1 = getFileList(in1)
	l2 = Array.sort(l1)
	for i in range (0, len(l2)):
		if os.path.isdir(os.path.join(in1, l2[i])):
		grabChannelsFromFolderesImage(in1 + File.separator + l2[i])
		if(endsWith(l2[i], suffix)): 
	 		ij.open(in1 + File.separator + l2[i])
			i = l2.length()
	Stack.getDimensions(width, height, channels, slices, frames)
	return channels
}