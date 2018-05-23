APP_NAME= cyril
PLATS   = linux windows macos

# Default compiler, will be overriden by a platform specific one if needed
CC 		= gcc
BLENDER = etc/bin/blender
PYTHON  = python

CFLAGS	= -Wall -O2 -Iinclude
LDFLAGS = -lm

ENGINE  := $(addprefix src/engine/,render/glext.o assets/pack.o)
OBJS	:= $(ENGINE) src/game/main.o


#
# Detect platform
#
ifeq ($(OS),Windows_NT)
	OSFLAG = windows
else
	uname_s := $(shell uname -s)
	ifeq ($(uname_s),Linux)
		OSFLAG = linux
	else ifeq ($(uname_s),Darwin)
		CC 	   = clang
		OSFLAG = macos
	else
		OSFLAG = unsupported
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
	@find src include tools -name "*.c" -o -name "*.m" -o -name "*.h" ! -name "glcorearb.h" -o -name "*.py" | xargs wc -l Makefile

exts_sort:
	mv glextensions.lst tmp/glextensions.lst && uniq tmp/glextensions.lst | sort > glextensions.lst

tmp/used_glexts.lst: glextensions.lst
	@< glextensions.lst xargs -J% -n1 fgrep -m1 -Iwhro --exclude="glext.*" % src > tmp/used_glexts.lst ||:

exts_unused: tmp/used_glexts.lst
	@diff -y glextensions.lst tmp/used_glexts.lst ||:

exts_optimized: tmp/used_glexts.lst
	mv glextensions.lst tmp/glextensions.lst && cp tmp/used_glexts.lst glextensions.lst

clean: clean_exe clean_pak clean_test clean_tmp
	find ./src ./include -name "glext.*" | xargs rm

clean_tmp:
	ls tmp/ | grep -v .gitkeep | sed 's/^/tmp\//' | xargs rm -rf

#
# Engine compilation
#
bin/$(APP_NAME): include/cyril.h include/glext.h $(OBJS) src/engine/sys/$(OSFLAG).o
	@make build_$(OSFLAG)

build_linux: include/cyril.h include/glext.h $(OBJS) src/engine/sys/linux.o
	$(CC) $(CFLAGS) $(OBJS) src/engine/sys/linux.o -o bin/$(APP_NAME) $(LDFLAGS) -lGL -lX11 -ldl

build_windows: include/cyril.h include/glext.h $(OBJS) src/engine/sys/windows.o
	$(CC) $(CFLAGS) $(OBJS) src/engine/sys/windows.o -o bin/$(APP_NAME).exe $(LDFLAGS) -lopengl32 -lwin32

build_macos: include/cyril.h include/glext.h $(OBJS) src/engine/sys/macos.o
	$(CC) $(CFLAGS) $(OBJS) src/engine/sys/macos.o -o bin/$(APP_NAME) $(LDFLAGS) -ldl \
	-framework Cocoa -framework OpenGL -framework CoreVideo -framework CoreAudio -framework GameController

build_unsupported:
	@echo "Could not automatically detect the OS"
	@echo "please execute:"
	@echo "   make PLATFORM"
	@echo "where PLATFORM is one of these:"
	@echo "   $(PLATS)"
	@echo "See readme.md for more info."

include/glext.h: glextensions.lst
	$(PYTHON) tools/glext.py -e glextensions.lst -c src/engine/render/glext.c -i include/glext.h -a include/gl/glcorearb.h -d1

clean_exe:
	find ./src -name "*.o" | xargs rm
	rm bin/$(APP_NAME)

clean_test:
	ls test/ | grep -v .gitkeep | sed 's/^/test\//' | xargs rm -rf

#
# PACK build
#


tmp/lv1.lst: $(shell find data/lv1 -type f)
	find ./data/lv1 -type f > tmp/lv1.lst

bin/lv1.pak: tmp/lv1.lst
	$(PYTHON) tools/pack.py -c data/lv1 bin/lv1.pak

clean_pak:
	find ./bin -name "*.pak" | xargs rm


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


