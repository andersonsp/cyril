#! /usr/bin/env python

import os
import shutil
import argparse
from string import Template

parser = argparse.ArgumentParser(description='OSX Bundle: create skeleton MacOS App bundles')
parser.add_argument('-o', '--out', help='Output directory, defaults to current directory', required=True)
parser.add_argument('-b', '--bin', help='Main binary to include', required=True)
parser.add_argument('-r', '--res-dir', help='Path to the resources (e.g. where the binary and supporting files are)', required=True)
parser.add_argument('--with-loader', help='Wether to add a loader script, so $PWD is set to the location of the binary', action="store_true")
parser.add_argument('--icon', help='Path to the icon to use, defaults to generic mac app icon')
parser.add_argument('--bundle', help='Name of the bundle, defaults to binary name')
parser.add_argument('--overwrite', help='Overwrite the contents if they exist', action="store_true")

PLIST_TPL = Template('''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
      <key>CFBundleGetInfoString</key>
      <string>$APP_NAME</string>
      <key>CFBundleExecutable</key>
      <string>$EXE_NAME</string>
      <key>CFBundleIdentifier</key>
      <string>$APP_NAME</string>
      <key>CFBundleName</key>
      <string>$APP_NAME</string>
      <key>CFBundleIconFile</key>
      <string>$APP_NAME.icns</string>
      <key>CFBundleInfoDictionaryVersion</key>
      <string>6.0</string>
      <key>CFBundlePackageType</key>
      <string>APPL</string>
      <key>NSHighResolutionCapable</key>
      <true/>
    </dict>
</plist>
''')

LOADER_TPL = Template("#! /usr/bin/env bash\ncd \"${0%/*}\"\n./$EXE_NAME\n")

DEFAULT_ICON = '/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericApplicationIcon.icns'
LOADER_NAME = '__loader__'

def dir_exists(path):
    return os.path.isdir(path) and os.path.exists(path)

def dir_copy(src, dst):
    '''copy a directory tree, ignoring symbolic links'''
    if not dir_exists(dst):
        os.makedirs(dst)

    for name in os.listdir(src):
        srcname = os.path.join(src, name)
        dstname = os.path.join(dst, name)

        if os.path.isdir(srcname):
            dir_copy(srcname, dstname)
        elif not os.path.islink(srcname):
            shutil.copy2(srcname, dstname)

def write_plist(bundle_path, app_name, exe_name):
    path = os.path.join(bundle_path, 'Info.plist')
    with open(path, 'w') as f:
        f.write(PLIST_TPL.substitute(APP_NAME=app_name, EXE_NAME=exe_name))

def write_loader(bundle_path, exe_name):
    loader_path = os.path.join(bundle_path, 'MacOS', LOADER_NAME)
    with open(loader_path, 'w') as f:
        f.write(LOADER_TPL.safe_substitute(EXE_NAME=exe_name))
    os.chmod(loader_path, 0755)

def create_bundle_structure(bundle_path, res):
    dir_copy(res, os.path.join(bundle_path, 'MacOS'))
    res_path = os.path.join(bundle_path, 'Resources')
    if not dir_exists(res_path):
        os.makedirs(res_path)

def copy_icon(bundle_path, app_name, icon):
    shutil.copy(icon, os.path.join(bundle_path, 'Resources', app_name+'.icns'))

def bundle(args):
    app_name = args.bin if args.bundle == None else args.bundle
    app_dir = os.path.join(args.out, app_name+'.app')
    contents_dir = os.path.join(app_dir, 'Contents')

    if dir_exists(app_dir) and not args.overwrite:
        raise RuntimeError('App bundle "%s" already exists' % app_name)

    # this creates the bundle base structure and copies the executable and support files
    create_bundle_structure(contents_dir, args.res_dir)

    exe_name = args.bin
    if args.with_loader:
        exe_name = LOADER_NAME
        write_loader(contents_dir, args.bin)

    write_plist(contents_dir, app_name, exe_name)

    icon = DEFAULT_ICON if args.icon == None else args.icon
    copy_icon(contents_dir, app_name, icon)

#
# Main
#

bundle(parser.parse_args())

