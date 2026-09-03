# Building Guide

## Introduction
This document explains how to build the bitwise operations submodule.

## Linux and macOS
Invoke `make` from the `qbitops` directory.
```Bash
cd qbitopts
make
mv bitops.*.so ../ax
```

## Windows
The Windows version of the module can be cross-compiled on Linux using MinGW-w64.
```Bash
cd qbitopts
CC=x86_64-w64-mingw32-gcc make
mv bitops.*.dll ../ax
```
