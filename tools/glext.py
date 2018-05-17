#! /usr/bin/env python

import pickle
import argparse
import os
import re

parser = argparse.ArgumentParser(description='glext opengl loader generator script')
parser.add_argument('-a', '--arb', help='Load corearb.h file', required=True)
parser.add_argument('-e', '--extlist', help='List of extensions to include', required=True)
parser.add_argument('-c', '--c-file', help='Path of the generated C file', required=True)
parser.add_argument('-i', '--h-file', help='Path of the include header file', required=True)
parser.add_argument('-d', '--debug', type=int, choices=[0, 1, 2],
    help='Level of debug info > 0 == pointer checks for all extensions')

args = parser.parse_args()


EXT_SUFFIX = ['ARB', 'EXT', 'KHR', 'OVR', 'NV', 'AMD', 'INTEL']

def is_ext(proc):
    return any(proc.endswith(suffix) for suffix in EXT_SUFFIX)

def get_arb_procs(arb):
    procs = []
    pkl = os.path.join('tmp', os.path.basename(arb) + '.pkl')
    p = re.compile(r'GLAPI.*APIENTRY\s+(\w+)')
    try:
        pkl_file = open(pkl)
        procs = pickle.load(pkl_file)
        pkl_file.close()
    except:
        with open(arb, 'r') as f:
            for line in f:
                m = p.match(line)
                if not m:
                    continue
                proc = m.group(1)
                if not is_ext(proc):
                    procs.append(proc)

        with open(pkl, 'wb') as db:
            pickle.dump(procs, db, -1)
    return procs

def get_extensions(extfile):
    exts = []
    with open(extfile, 'r') as f:
        for line in f:
            s = line.strip()
            if len(s) > 0:
                exts.append(s)
    return exts

def validate_extensions(procs, exts):
    for ext in exts:
        if ext not in procs:
            raise RuntimeError('invalid extension %s' % s)

def gen_ext_files(procs, exts, c_file, h_file, debug):

    header_name = h_file.split('/')[-1].upper().replace('.', '_')
    with open(h_file, 'w') as f:
        f.write('#ifndef %s_H_INCLUDED\n' % header_name)
        f.write('#define %s_H_INCLUDED\n' % header_name)
        f.write('#include <gl/glcorearb.h>\n')
        f.write('\n')
        f.write('int glext_init(void* mod);\n')
        f.write('void* glext_proc_addr(void* mod, char* name);\n')
        f.write('\n')
        for ext in exts:
            f.write('extern PFN%sPROC %s;\n' % (ext.upper(), ext))
        f.write('#endif // %s_H_INCLUDED\n' % header_name)

    with open(c_file, 'w') as f:
        f.write('#include <%s>\n' % os.path.basename(h_file))
        f.write('\n')

        for ext in exts:
            f.write('PFN%sPROC %s;\n' % (ext.upper(), ext))

        f.write('\n')
        f.write('int glext_init(void* mod) {\n')
        for i, ext in enumerate(exts, 1):
            f.write('  %s = (PFN%sPROC) glext_proc_addr(mod, "%s");\n' % (ext, ext.upper(), ext))
            if debug == 2:
                f.write('  if(!%s) {\n' % ext)
                f.write('    printf("Could not load extension %%s\\n", "%s");\n' % ext)
                f.write('    return %d;\n' % i)
                f.write('  }\n' % ext)
            elif debug == 1:
                f.write('  if(!%s) return %d;\n' % (ext, i))
        f.write('  return 0;\n')
        f.write('}\n')

#
# Main
#
procs = get_arb_procs(args.arb)
exts = get_extensions(args.extlist)
validate_extensions(procs, exts)
# print(exts)
gen_ext_files(procs, exts, args.c_file, args.h_file, args.debug)
