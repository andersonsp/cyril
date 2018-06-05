APP_NAME= cyril
PLATS   = linux windows macos

# Default compiler, will be overriden by a platform specific one if needed
CC 		= gcc
BLENDER = etc/bin/blender
PYTHON  = python

CFLAGS	= -Wall -O2 -Iinclude
LDFLAGS = -lm

ENGINE_UTIL 	:= $(addprefix util/, pipe.o mem.o)
ENGINE_RENDER	:= $(addprefix render/, glext.o)
ENGINE_ASSETS 	:= $(addprefix assets/, pack.o)
ENGINE_MATH     := $(addprefix math/, vec.o matrix.o quat.o)
ENGINE  		:= $(addprefix src/engine/,$(ENGINE_RENDER) $(ENGINE_ASSETS) $(ENGINE_MATH) $(ENGINE_UTIL))

GAME    := $(addprefix src/game/, main.o)

OBJS	:= $(ENGINE) $(GAME)


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

.DEFAULT_GOAL := help
.PHONY: help
help:
	@grep -E '(^[a-zA-Z_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m==/'

## Main
#
all:  bin/$(APP_NAME) bin/lv1.pak ## Compile all (autodetect platform)

run: bin/$(APP_NAME) bin/lv1.pak ## Compile and run the project
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
## House keeping
#
count: ## Count LOCs in the project
	@find src include tools -name "*.c" -o -name "*.m" -o -name "*.h" ! -name "glcorearb.h" -o -name "*.py" | xargs wc -l Makefile

exts_sort: ## Sort gl extensions list (keeps a backup in /tmp)
	mv glextensions.lst tmp/glextensions.lst && uniq tmp/glextensions.lst | sort > glextensions.lst

tmp/used_glexts.lst: glextensions.lst
	@< glextensions.lst xargs -J% -n1 fgrep -m1 -Iwhro --exclude="glext.*" % src > tmp/used_glexts.lst ||:

exts_unused: tmp/used_glexts.lst ## Show unused extensions
	@diff -y glextensions.lst tmp/used_glexts.lst ||:

exts_optimized: tmp/used_glexts.lst ## Remove unused extensions (keeps a backup in /tmp)
	mv glextensions.lst tmp/glextensions.lst && cp tmp/used_glexts.lst glextensions.lst

clean: clean_exe clean_pak clean_test clean_tmp ## Clean everything
	find ./src ./include -name "glext.*" | xargs rm

clean_tmp: ## -
	ls tmp/ | grep -v .gitkeep | sed 's/^/tmp\//' | xargs rm -rf

#
# Engine compilation
#
bin/$(APP_NAME): include/cyril.h include/glext.h $(OBJS) src/engine/sys/$(OSFLAG).o
	@make build_$(OSFLAG)

build_linux: include/cyril.h include/glext.h $(OBJS) src/engine/sys/linux.o
	$(CC) $(CFLAGS) $(OBJS) src/engine/sys/linux.o -o bin/$(APP_NAME) $(LDFLAGS) -lGL -lX11 -ldl -lpthread

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


## Tests
#

test/bin/%: test/src/%.o src/%.o
	@[ -d $(@D) ] || mkdir -p $(@D)
	$(CC) $^ -o $@

.PHONY: test
test: $(shell find test/src -name "*.c" -type f | sed 's/^test\/src/test\/bin/;s/.c$$//') ## Compile and execute all tests in /test dir
	@printf "\e[1mRunning tests...\e[0m\n"
	sh -c $?

clean_test: ## Clean test artifacts
	# ls test/ | grep -v .gitkeep | sed 's/^/test\//' | xargs rm -rf


#
## Pack build
#

packs: ## Build all packs in /data dir
	@echo TODO

tmp/lv1.lst: $(shell find data/lv1 -type f)
	find ./data/lv1 -type f > tmp/lv1.lst

bin/lv1.pak: tmp/lv1.lst
	$(PYTHON) tools/pack.py -c data/lv1 bin/lv1.pak

clean_pak: ## -
	find ./bin -name "*.pak" | xargs rm


# =============================
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


