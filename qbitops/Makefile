M := $(shell $(CC) -dumpmachine)
P := $(if $(filter %-linux-gnu,$M),l)$(if $(findstring -apple-,$M),m)$(if $(filter %-mingw32 %-msvc,$M),w)
A := $P
A := $(if $A,$A$(if $(filter x86_64-%,$M),i64)$(if $(filter aarch64-% arm64-%,$M),a64))

$(if $A,,$(error couldn't determine target platform: $(CC) -dumpmachine reports $M))

H := $(shell uname -o 2>/dev/null || echo Windows)

O := o
E := so

ifeq ($P,w)
  O    := obj
  E    := dll
endif

CROSS := $(if $(and $(findstring w,$P),$(findstring Linux,$H)),x86_64-w64-mingw32-)
CC    := $(CROSS)gcc

CFLAGS := -std=gnu99 -fvisibility=hidden -fPIC -DKXVER=3 -I.

ifdef DEBUG
  CFLAGS += -gdwarf-2 -g3 -O0
else
  CFLAGS += -O2
endif

ifeq ($A,li64)
  CFLAGS  += -z noexecstack -include force_link_glibc_2.17.h
  LDLIBS  += -ldl
endif

ifeq ($P,m)
  CFLAGS  += -Wno-parentheses -Wno-pointer-sign
  LDFLAGS  = -undefined dynamic_lookup -bundle
else ifeq ($P,w)
  CFLAGS  += -m64
  LDFLAGS  = -shared
else
  LDFLAGS  = -shared
endif

SRCS    := bitops.c
OUT     := bitops.$A.$E

.PHONY: all clean

all: $(OUT)

DLLTOOL := $(CROSS)dlltool
NM      := $(CROSS)nm

ifeq ($P,w)
all: $(OUT)
$(OUT): libq.a
q.lib:
	wget -q https://github.com/KxSystems/kdb/raw/master/w64/q.lib
q.def: q.lib
	echo 'LIBRARY q.exe' > $@
	echo EXPORTS          >> $@
	$(NM) -p $< | grep 'T [a-zA-Z]' | sed 's/0* T //' >> $@
	echo vk               >> $@
libq.a: q.def
	$(DLLTOOL) -l $@ -d $<
endif

$(OUT): $(SRCS)
	$(CC) $(CFLAGS) $(LDFLAGS) $^ $(LDLIBS) -o $@

clean:
	$(RM) $(OUT) *.$(O) q.lib q.def libq.a
