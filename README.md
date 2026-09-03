# AX Module

The KDB-X AX module exposes components from the [AxLibraries](https://code.kx.com/developer/libraries/#q-libraries) using the modules framework. The current components that have been ported across are:

- [Grammar of Graphics](https://code.kx.com/developer/ggplot/) (ggplot) 
- [qDoc](https://code.kx.com/developer/libraries/#qdoc)


## Prerequisites

The KX Fusionx PCRE2 and Skia modules are required dependencies and need to be loaded via
```q
use`kx.fusion:pcre2
use`kx.skia
```
Respective installation instructions:
* [PCRE2](https://github.com/KxSystems/fusionx/blob/main/README.md)
* [Skia](https://github.com/KxSystems/qskia/blob/main/README.md)

## Build Instructions

The AX module contains a bitwise operations submodule (`qbitops`) which has a compilation step. 

:point_right: [`Build guide`](docs/build.md)

## Installation Documentation

:point_right: [`Install guide`](docs/install.md)

## API Documentation

The APIs match the AxLibraries APIs, with the benefit of being loadable to any namespace.

```q
([qp;gg;qd]):use`kx.ax;         // all components
([qd]):use`kx.ax.qdoc;          // or more granularly 
([qp;gg]):use`kx.ax.graphics;
```

Simply replace `.qp`, `.gg` and `.qd` with `qp`, `gg` and `qd` respectively when referencing the AxLibraries API specifications (or the namespace you have chosen to assign the components to).

:point_right: [GGPlot](https://code.kx.com/analyst/libraries/grammar-of-graphics/)
:point_right: [qDoc](https://code.kx.com/developer/libraries/documentation-generator/)

## Notice

Copyright (c) 2026 KX Systems, Inc.

Licensed under the Apache License, Version 2.0.
