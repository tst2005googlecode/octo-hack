#!/usr/bin/python
# This script walks recursivly thorugh the entire structure opens files and converts them to unix newlines and makes sure there is a newline at the end
import os

def isOneOf(x, lst):
	for l in lst:
		if x == l:
			return True
	return False

def fixFile(file):
	ext = os.path.splitext(file)[1][1:]
	if isOneOf(ext, ["c", "cpp", "cxx", "h", "hpp", "lua"]):
		print "fixing " + file
		with open(file) as f:
			lines = f.readlines()
		with open(file, 'wb') as f:
			for line in lines:
				f.write(line.rstrip() + "\n")

def walkDirs(path):
	for name in os.listdir(path):
		dir = os.path.join(path, name)
		if os.path.isdir(dir):
			walkDirs(dir)
		elif os.path.isfile(dir):
			fixFile(dir)


walkDirs( os.getcwd() )
