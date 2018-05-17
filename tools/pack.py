#! /usr/bin/env python
# Based on https://tomeofpreach.wordpress.com/2013/06/22/makepak-py/

import os
import sys
import struct
import argparse

parser = argparse.ArgumentParser(description='Pack: create Cyril pack files')
parser.add_argument('pack', help='Pack file')
group = parser.add_mutually_exclusive_group()
group.add_argument('-c', '--create', help='Directory to add to the pack file')
group.add_argument('-l', '--list', help='List entries stored on the pack file', action="store_true")

#dummy class for stuffing the file headers into
class FileEntry:
    pass

MAGIC = b"CYPK"
FILE_HEADER = struct.Struct("<l")
PAK_HEADER = struct.Struct("<4s3l")
PAK_ENTRY = struct.Struct("<56s2l")

def create_entry(pakfile, entry_filename, source_dir, offset):
    entry = FileEntry()
    entry.filename = os.path.relpath(entry_filename, source_dir).replace("\\","/")
    file_size = os.path.getsize(entry_filename)

    with open(entry_filename, "rb") as importfile:
        entry.offset = offset
        entry.length = file_size
        # padd to a multiple of 4
        entry.pad = (-file_size & 3)

        pakfile.write(FILE_HEADER.pack(file_size))
        pakfile.write(importfile.read())
        pakfile.write('\0'*entry.pad)
    return entry


def create_pak(source_dir, pak_filename):
    with open(pak_filename,"wb") as pakfile:
        #write a dummy header to start with
        pakfile.write(PAK_HEADER.pack(MAGIC,1, 0, 0))

        #walk the directory recursively, add the files and record the file entries
        offset = 0
        fileentries = []
        for root, subFolders, files in os.walk(source_dir):
            for file in files:
                entry = create_entry(pakfile, os.path.join(root, file), source_dir, offset)
                offset += FILE_HEADER.size + entry.length + entry.pad
                fileentries.append(entry)

        #after all the file data, write the list of entries
        tablesize = 0
        for entry in fileentries:
            pakfile.write(PAK_ENTRY.pack(entry.filename.encode("ascii"), entry.offset, entry.length))
            tablesize = tablesize + PAK_ENTRY.size

        #return to the header and write the values correctly
        pakfile.seek(0)
        pakfile.write(PAK_HEADER.pack(MAGIC, 1, offset, tablesize))

def list_pak(pak_filename):
    with open(pak_filename,"rb") as f:
        header = PAK_HEADER.unpack(f.read(PAK_HEADER.size))
        if header[0] != MAGIC:
            raise RuntimeError('Nota valid Cyril Pak file %s' % pak_filename)

        f.seek(header[2], 1)

        print("\n%-8s %-56s %-8s" % ("Addr", "File name", "Size"))
        print("%-8s %-56s %-8s" % ('_'*8, '_'*56, '_'*8))
        count = header[3] / PAK_ENTRY.size
        for x in xrange(0, count):
            entry = PAK_ENTRY.unpack(f.read(PAK_ENTRY.size))
            print("[%6d] %-56s %7db" % (entry[1], entry[0].rstrip('\0'), entry[2]))
        print("%-8s %-56s %-8s" % ('_'*8, '_'*56, '_'*8))
        print("%4d Files -- %8d Bytes\n" % (count, PAK_HEADER.size + header[2] + header[3]))


#
# Main
#

args = parser.parse_args()

if args.create != None:
    create_pak(args.create, args.pack)
elif args.list:
    list_pak(args.pack)
else:
    args.print_help()

