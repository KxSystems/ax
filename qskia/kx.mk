# K(directory with k.h) M(machine triple, e.g. x86_64-linux-gnu) A(q arch, e.g. li64) E(extension, .so or .dll)

K:=$(dir $(lastword $(MAKEFILE_LIST)))
M:=$(shell $(CC) -dumpmachine)
A:=$(if $(filter %-linux-gnu,$M),l)$(if $(findstring -apple-,$M),m)$(if $(filter %-mingw32 %-msvc,$M),w)
A:=$(if $A,$A$(if $(filter x86_64-%,$M),i64)$(if $(filter aarch64-% arm64-%,$M),a64))
$(if $A,,$(error couldn't determine the target platform: $(CC) -dumpmachine reports $M))
E:=$(if $(filter w%,$A),dll,so)

