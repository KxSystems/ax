CC       = $(if $(findstring osx_x64,$(MAKECMDGOALS)),arch -x86_64) g++
RM       = rm -rf
LIBS     = -lskia
SKIA_DIR = ./deps/skia
SKIA_INC = $(SKIA_DIR)/include
INCLUDES = -I./src -I$(SKIA_DIR) -I$(SKIA_INC)/core -I$(SKIA_INC)/encode -I$(SKIA_INC)/effects -I$(SKIA_INC)/ports
DEFINES  = -DKXVER=3 -DSK_INTERNAL -DSK_GAMMA_SRGB -DSK_GAMMA_APPLY_TO_A8 -DSK_SCALAR_TO_FLOAT_EXCLUDED -DSK_ALLOW_STATIC_GLOBAL_INITIALIZERS=1 -DSK_SUPPORT_GPU=1 -DSK_SUPPORT_OPENCL=0 -DSK_FORCE_DISTANCEFIELD_FONTS=0 -DSK_SCALAR_IS_FLOAT -DSK_SAMPLES_FOR_X -DSK_BUILD_FOR_UNIX -DSK_USE_POSIX_THREADS -DSK_DEBUG -DSK_DEVELOPER=1
WARNINGS = -Wall -Wextra -Wno-unused-parameter -Wno-unused-variable
FLAGS    = -std=c++17 -O3 -fPIC
CFLAGS   = $(WARNINGS) $(DEFINES) $(FLAGS) $(INCLUDES)
LDFLAGS  = -L$(SKIA_DIR)/out/Static

include kx.mk

NAME    = skia.$A.$E
TEST    =
OUTDIR  = ./dist
TESTDIR = ./test_run

SOURCES      = $(wildcard src/*.cpp)
WRAPPERS     = $(wildcard src/wrappers/*.cpp)
TESTS        = $(wildcard tests/*.cpp)
DEPS         = $(wildcard src/*.d src/wrappers/*.d)
SRC_OBJECTS  = $(patsubst %.cpp,%.o,$(SOURCES))
WRAP_OBJECTS = $(patsubst %.cpp,%.o,$(WRAPPERS))
TEST_OBJECTS = $(patsubst %.cpp,%.o,$(TESTS))

all: $(OUTDIR)/$(NAME)

all_x64: FLAGS += -m64
all_x64: all

linux_x64: FLAGS += -Wl,-rpath='$$ORIGIN'
linux_x64: LIBS  += -lfontconfig
linux_x64: all_x64

osx_x64: FLAGS += -undefined dynamic_lookup -Qunused-arguments -framework CoreFoundation -framework CoreGraphics -Wl,-install_name,$(NAME)
osx_x64: all_x64

osx_arm64: osx_x64

-include $(DEPS)

$(OUTDIR)/$(NAME): $(SRC_OBJECTS) $(WRAP_OBJECTS)
	mkdir -p $(OUTDIR)
	$(CC) $(CFLAGS) $(SRC_OBJECTS) $(WRAP_OBJECTS) $(LIBS) $(LDFLAGS) -shared -o $(OUTDIR)/$(NAME)

$(TEST): $(SRC_OBJECTS) $(TEST_OBJECTS)
	mkdir -p $(TESTDIR)
	$(CC) $(CFLAGS) $^ $(LIBS) -lcriterion -o $(TEST)

test : $(TEST)
	cp -a $(OUTDIR)/* $(TESTDIR)
	export LD_LIBRARY_PATH=$$LD_LIBRARY_PATH:/usr/local/lib; $(TESTDIR)/$(TEST)

.PHONY: clean
clean:
	$(RM) $(OUTDIR) $(TESTDIR) $(SRC_OBJECTS) $(WRAP_OBJECTS) $(TEST) $(TEST_OBJECTS) $(DEPS)

%.o: %.cpp
	$(CC) $(CFLAGS) -MMD -MP -o $@ -c $<
