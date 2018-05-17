#! /usr/bin/env python
# Based on https://tomeofpreach.wordpress.com/2013/06/22/makepak-py/


import os
import sys
import struct
import argparse


parser = argparse.ArgumentParser(description='OSX Bundle: create skeleton MacOS App bundles')
parser = argparse.ArgumentParser(description='OSX Bundle: create skeleton MacOS App bundles')
parser.add_argument('path', help='Directory to add to the pack file')
parser.add_argument('-c', '--create', help='Output pack file')
parser.add_argument('-x', '--extract', help='Extract the contents of the pack file')
parser.add_argument('-l', '--list', help='List entries stored on the pack file')


#
# TODO: Implement arguments parsing
#



#dummy class for stuffing the file headers into
class FileEntry:
    pass

# each entry in the
FILE_HEADER_SZ = struct.Struct("<l").size

#arguments are source directory, then target filename e.g. "pak1.pak"
rootdir = sys.argv[1]
pakfilename = sys.argv[2]

pakfile = open(pakfilename,"wb")

#write a dummy header to start with
pakfile.write(struct.Struct("<4s3l").pack(b"LPAK",1, 0, 0))

#walk the directory recursively, add the files and record the file entries
offset = 0
fileentries = []
for root, subFolders, files in os.walk(rootdir):
    for file in files:
        entry = FileEntry()
        impfilename = os.path.join(root,file)
        entry.filename = os.path.relpath(impfilename, rootdir).replace("\\","/")
        file_size = os.path.getsize(impfilename)

        with open(impfilename, "rb") as importfile:
            entry.offset = offset
            entry.length = file_size

            # write file header
            pakfile.write(struct.Struct("<l").pack(file_size))

            # write file
            pakfile.write(importfile.read())

            # padd to a multiple of 4
            pad = (-file_size & 3)
            pakfile.write('\0'*pad)
            offset += FILE_HEADER_SZ + file_size + pad

        fileentries.append(entry)


#after all the file data, write the list of entries
tablesize = 0
for entry in fileentries:
    pakfile.write(struct.Struct("<56s").pack(entry.filename.encode("ascii")))
    pakfile.write(struct.Struct("<l").pack(entry.offset))
    pakfile.write(struct.Struct("<l").pack(entry.length))
    tablesize = tablesize + 64

#return to the header and write the values correctly
pakfile.seek(0)
pakfile.write(struct.Struct("<4s3l").pack(b"LPAK", 1, offset, tablesize))
