#
# General Compiler Settings
#

CC=g++
#GCW0=1
SDL=2
DEBUG=0

# general compiler settings
ifeq ($(M32),1)
	FLAGS= -m32
endif
ifeq ($(GCW0),1)
 	# Build GL4ES first with these options : cmake ../gl4es -DCMAKE_TOOLCHAIN_FILE=/opt/gcw0-toolchain/usr/share/buildroot/toolchainfile.cmake -DNOX11=ON
    CC= /opt/gcw0-toolchain/usr/bin/mipsel-gcw0-linux-uclibc-g++
	FLAGS=    -O3
	FLAGS+=   -DGCW0 -Dlinux
	FLAGS+=   -I../gl4es/include -I../GLU/include
	FLAGS+=   -L../gl4es/lib -L../GLU/lib
	#HAVE_GLES=1
endif
ifeq ($(PANDORA),1)
	FLAGS= -mcpu=cortex-a8 -mfpu=neon -mfloat-abi=softfp -march=armv7-a -fsingle-precision-constant -mno-unaligned-access -fdiagnostics-color=auto -O3 -fsigned-char
	FLAGS+= -DPANDORA
	FLAGS+= -DARM
	LDFLAGS= -mcpu=cortex-a8 -mfpu=neon -mfloat-abi=softfp
	#HAVE_GLES=1
endif
ifeq ($(PYRA),1)
        FLAGS= -mcpu=cortex-a15 -mfpu=neon -mfloat-abi=hard -fsingle-precision-constant
        FLAGS+= -DPYRA
        FLAGS+= -DARM
        LDFLAGS= -mcpu=cortex-a8 -mfpu=neon -mfloat-abi=softfp
endif
ifeq ($(ODROID),1)
        FLAGS= -mcpu=cortex-a9 -mfpu=neon -mfloat-abi=hard -fsingle-precision-constant -O3 -fsigned-char
        FLAGS+= -DODROID
        FLAGS+= -DARM
        LDFLAGS= -mcpu=cortex-a9 -mfpu=neon -mfloat-abi=hard
        #HAVE_GLES=1
endif
ifeq ($(ODROIDN1),1)
        FLAGS= -mcpu=cortex-a72.cortex-a53 -fsingle-precision-constant -O3 -fsigned-char -ffast-math
        FLAGS+= -DODROID
        FLAGS+= -DARM
        LDFLAGS= -mcpu=cortex-a72.cortex-a53
        #HAVE_GLES=1
endif
ifeq ($(CHIP),1)
        FLAGS= -mcpu=cortex-a8 -mfpu=neon -mfloat-abi=hard -fsingle-precision-constant -O3 -fsigned-char
        FLAGS+= -DCHIP
        FLAGS+= -DARM
        LDFLAGS= -mcpu=cortex-a8 -mfpu=neon -mfloat-abi=hard
        #HAVE_GLES=1
endif
ifeq ($(EMSCRIPTEN),1)
        FLAGS= -s FULL_ES2=1 -I../gl4es/include -s USE_SDL_TTF=2 -s USE_SDL=2
        FLAGS+= -I/usr/include/glm
        FLAGS+= -Dlinux -DUSE_SDL2
        FLAGS+= --emrun --preload-file Tracks --preload-file Sounds
        FLAGS+= --preload-file Bitmap --embed-file DejaVuSans-Bold.ttf
        FLAGS+= --shell-file template.html
        LDFLAGS= -s FULL_ES2=1 -s USE_SDL_TTF=2 -s USE_SDL=2
        CC= emcc
        CXX= emc++
endif

FLAGS+= -pipe -fpermissive
CFLAGS=$(FLAGS) -Wno-conversion-null -Wno-write-strings -ICommon
LDFLAGS=$(FLAGS)

ifeq ($(PANDORA),1)
	PROFILE=0
else
	PROFILE=0
endif


ifeq ($(DEBUG),1)
	FLAGS+= -g
	CFLAGS+=-O2
else
	CFLAGS+=-O3 -Winit-self
	LDFLAGS+=-s
endif

ifeq ($(PROFILE),1)
	ifneq ($(DEBUG),1)
		# Debug symbols needed for profiling to be useful
		FLAGS+= -g
	endif
	FLAGS+= -pg
endif


ifeq ($(EMSCRIPTEN),1)
	GL4ES = ../gl4es/lib/libGL.a
	LIB+= -lopenal ${GL4ES}
else
ifeq ($(SDL),2)
	SDL_=sdl2
	TTF_ = SDL2_ttf
	CFLAGS += -DUSE_SDL2
else
	SDL_=
	CFLAGS+=`sdl-config --cflags`
	TTF_ = SDL_ttf
endif

# library headers
ifeq ($(PANDORA),1)
	CFLAGS+= `pkg-config --cflags $(SDL_) $(TTF_) openal`
else
	CFLAGS+= `pkg-config --cflags $(SDL_) $(TTF_) openal`
endif

# dynamic only libraries
ifeq ($(PANDORA),1)
	LIB+= `sdl-config --libs`
else
	LIB+= `pkg-config --libs $(SDL_)`
endif

LIB+= `pkg-config --libs $(TTF_)`

ifeq ($(MINGW),1)
	LIB += -L./mingw/bin
	LIB += -lglu32 -lopengl32
	LIB += -lsocket -lws2_32 -lwsock32 -lwinmm -lOpenAL32
else
	ifeq ($(HAVE_GLES),1)
		LIB += -lGLES_CM -lEGL
		CFLAGS += -DHAVE_GLES
	else
		LIB += -lGL -lGLU
	endif
	LIB += -lopenal
endif
ifneq ($(MINGW),1)
	# apparently on some systems -ldl is explicitly required
	# perhaps this is part of the default libs on others...?
	LIB+= -ldl
endif
endif

# specific includes
CFLAGS += -I.
CFLAGS += -DSOUND_OPENAL

ifeq ($(DEBUG),1)
	CFLAGS+= -DDEBUG_ON -DDEBUG_COMP -DDEBUG_SPOTFX_SOUND -DDEBUG_VIEWPORT
endif

ifeq ($(EMSCRIPTEN),1)
BIN=docs/index.html
else
BIN=stuntcarracer
endif


INC=$(wildcard *.h)
SRC=$(wildcard *.cpp)
ifeq ($(EMSCRIPTEN),1)
OBJ=$(patsubst %.cpp,%.bc,$(SRC))
#Not in OBJ to avoid removal with a "clean" command
INC+=${GL4ES}
else
OBJ=$(patsubst %.cpp,%.o,$(SRC))
endif

all: $(BIN)

$(BIN): $(OBJ)
	$(CC) -o $(BIN) $(OBJ) $(CFLAGS) $(LDFLAGS) $(LIB)

$(OBJ): $(INC)

%.o: %.cpp
	$(CC) -o $@ -c $< $(CFLAGS)

%.bc: %.cpp
	$(CC) -o $@ -c $< $(CFLAGS)

clean:
	$(RM) $(OBJ) $(BIN)
	$(RM) -rf opk_data/Bitmap
	$(RM) -rf opk_data/Sounds
	$(RM) -rf opk_data/Tracks
	$(RM) -f opk_data/DejaVuSans-Bold.ttf
	$(RM) -f opk_data/stuntcarracer
	$(RM) -f stuntcarremake.opk

check:
	@echo
	@echo "INC = $(INC)"
	@echo
	@echo "SRC = $(SRC)"
	@echo
	@echo "OBJ = $(OBJ)"
	@echo
	@echo "DEBUG = $(DEBUG)"
	@echo "PROFILE = $(PROFILE)"
	@echo "PANDORA = $(PANDORA)"
	@echo "ODROID = $(ODROID)"
	@echo "CHIP = $(CHIP)"
	@echo "HAVE_GLES = $(HAVE_GLES)"
	@echo "SDL = $(SDL)"
	@echo "SDL_ = $(SDL_)"
	@echo
	@echo "CC = $(CC)"
	@echo "BIN = $(BIN)"
	@echo "CFLAGS = $(CFLAGS)"
	@echo "LDFLAGS = $(LDFLAGS)"
	@echo "LIB = $(LIB)"
	@echo

opk:
	cp -rf Bitmap opk_data
	cp -rf Sounds opk_data
	cp -rf Tracks opk_data
	cp -f DejaVuSans-Bold.ttf opk_data
	cp -f stuntcarracer opk_data
	rm -f stuntcarremake.opk
	mksquashfs opk_data stuntcarremake.opk
