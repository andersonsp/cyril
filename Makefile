APP_NAME= cyril
PLATS   = linux windows macos

# Default compiler, will be overriden by a platform specific one if needed
CC 		= gcc
BLENDER = etc/bin/blender
PYTHON  = python

CFLAGS	= -Wall -O2 -Iinclude
LDFLAGS = -lm

OBJS	= test/main.o src/glext.o src/pack.o


#
# Detect platform
#
ifeq ($(OS),Windows_NT)
    OSFLAG = windows
else
    uname_s := $(shell uname -s)
    ifeq ($(uname_s),Linux)
        OSFLAG = linux
    else
	    ifeq ($(uname_s),Darwin)
	    	CC 	   = clang
	        OSFLAG = macos
        else
			OSFLAG = unsupported
	    endif
    endif
endif

#
# Main
#
all:  bin/$(APP_NAME) bin/lv1.pak

run: bin/$(APP_NAME) bin/lv1.pak
	make run_$(OSFLAG)

run_linux:
	cd bin && ./$(APP_NAME)

run_windows:
	cd bin && ./$(APP_NAME).exe

run_macos: tmp/$(APP_NAME).app
	cd tmp && open -a $(APP_NAME).app


#
# Bundle management
#

tmp/$(APP_NAME).app: bin/$(APP_NAME)
	$(PYTHON) tools/macos_app.py -r bin -b $(APP_NAME) -o tmp --with-loader --overwrite
	touch tmp/$(APP_NAME).app

clean_bundle:
	rm -rf tmp/$(APP_NAME).app

#
# House keeping
#
count:
	wc -l Makefile src/*.c src/*.m include/*.h tools/*.py

sort_exts:
	mv glextensions.lst tmp/glextensions.lst && sort tmp/glextensions.lst > glextensions.lst

clean: clean_exe clean_pak clean_tmp
	rm src/glext.c
	rm include/glext.h

clean_tmp:
	ls tmp | grep -v .gitkeep | sed 's/^/tmp\//' | xargs rm -rf

#
# Engine compilation
#
bin/$(APP_NAME): include/cyril.h include/glext.h $(OBJS)
	make build_$(OSFLAG)

build_linux: include/cyril.h include/glext.h $(OBJS) src/sys_linux.o
	$(CC) $(CFLAGS) $(OBJS) src/sys_linux.o -o bin/$(APP_NAME) $(LDFLAGS) -lGL -lX11

build_windows: include/cyril.h include/glext.h $(OBJS) src/sys_windows.o
	$(CC) $(CFLAGS) $(OBJS) sys_windows.o -o bin/$(APP_NAME).exe $(LDFLAGS) -lopengl32 -lwin32

build_macos: include/cyril.h include/glext.h $(OBJS) src/sys_macos.o
	$(CC) $(CFLAGS) $(OBJS) src/sys_macos.o -o bin/$(APP_NAME) $(LDFLAGS) \
	-framework Cocoa -framework OpenGL -framework CoreVideo -framework CoreAudio -framework GameController

build_unsupported:
	@echo "Could not automatically detect the OS"
	@echo "please execute:"
	@echo "   make PLATFORM"
	@echo "where PLATFORM is one of these:"
	@echo "   $(PLATS)"
	@echo "See readme.md for more info."

include/glext.h: glextensions.lst
	$(PYTHON) tools/glext.py -e glextensions.lst -c src/glext.c -i include/glext.h -a include/gl/glcorearb.h -d1

clean_exe:
	rm src/*.o
	rm test/*.o
	rm bin/$(APP_NAME)


#
# PACK build
#
tmp/lv1.lst: $(shell find data/lv1 -type f)
	find data/lv1 -type f > tmp/lv1.lst

bin/lv1.pak: tmp/lv1.lst
	$(PYTHON) tools/pack.py -c data/lv1 bin/lv1.pak

clean_pak:
	rm bin/*.pak


############
#
# for these, use the same trick as with lv1.pak

#
# Fonts
#
data/lv1/font:
	$(PYTHON) sdf_font.py data/src/lv1/font.tga

#
# Models
#

data/lv1/model: data/lv1/model.geom data/lv1/model.anim

data/lv1/model.mesh:
	$(BLENDER) data/src/lv1/model.blend --background --python tools/lmesh.py data/lv1/model -geom

data/lv1/model.anim:
	$(BLENDER) data/src/lv1/model.blend --background --python tools/lmesh.py data/lv1/model -anim


#
# Maps
#
data/lv1/map: data/lv1/map.bsp data/lv1/map.points data/lv1/map.mesh

data/lv1/map.bsp:
	$(BLENDER) data/src/lv1/map.blend --background --python tools/map.py data/lv1/map -bsp -points

data/lv1/map.points:
	$(BLENDER) data/src/lv1/map.blend --background --python tools/map.py data/lv1/map -bsp -points

data/lv1/map.mesh:
	$(BLENDER) data/src/lv1/map.blend --background --python tools/lmesh.py data/lv1/map -geom


