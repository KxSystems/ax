#!/bin/bash
set -e
set -x

MODDIR=$PREFIX/lib/q/mod/kx/ax

mkdir -p $MODDIR
cp ax/graphics.q $MODDIR
cp ax/init.q $MODDIR
cp ax/qdoc.q $MODDIR

echo $target_platform

case "$target_platform" in
    linux-64)
        A=li64
        ;;
    linux-aarch64)
        A=la64
        ;;
    osx-64)
        A=mi64
        ;;
    osx-arm64)
        A=ma64
        ;;
    win-64)
        A=wi64
        ;;
    win-arm64)
        A=wa64
        ;;
    *)
        A=unknown
        ;;
esac

echo $A

if [[ "$target_platform" == win* ]]; then
    E=dll
    export CC=x86_64-w64-mingw32-gcc
else
    E=so
fi

cd qbitops
make
cp bitops.$A.$E $PREFIX/lib/q/mod/kx/ax
