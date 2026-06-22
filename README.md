# AX Module

The kdb-x ax module exposes components from the [ax-libraries](https://code.kx.com/developer/libraries/#q-libraries) under the modules framework. The current components that have been ported across are:

- [Grammar of Graphics](https://code.kx.com/developer/ggplot/) (ggplot) 
- [qDoc](https://code.kx.com/developer/libraries/#qdoc)


## Prerequisites

Fusionx pcre2 is a required module, and needs to be callable via

```q
use`kx.fusion:pcre2
```

The install instructions for that can be found [here](https://github.com/KxSystems/fusionx/blob/main/README.md)

## Build Instructions

These instructions are for building from source, the pre-built module is available under [releases](https://github.com/KxSystems/ax/tags). 

Outside of fusionx pcre2, there are two kdb-x submodules included in this repo required for ggplot specifically. These are:

- [qskia](./qskia) -> skia.$A.(so|dll)
- [qbitops](./qbitops) -> bitops.$A.(so|dll)

After building each from their respective directories, move the built shared libraries to the [ax](./ax) folder. Now it is ready to be installed.

## Installation Documentation

:point_right: [`Install guide`](docs/install.md)

## API Documentation

The APIs match the ax-libraries APIs, with the benefit of being loadable to any namespace.

```q
([qp;gg;qd]):use`kx.ax;         // all components
([qd]):use`kx.ax.qdoc;          // or more granularly 
([qp;gg]):use`kx.ax.graphics;
```

Simply replace `.qp`, `.gg` and `.qd` with `qp`, `gg` and `qd` respectively when referencing the ax-libraries API specifications (or the namespace you have chosen to assign the components to).

:point_right: [GGPlot](https://code.kx.com/analyst/libraries/grammar-of-graphics/)
:point_right: [qDoc](https://code.kx.com/developer/libraries/documentation-generator/)

## Notice

Copyright (c) 2026 KX Systems, Inc.

Licensed under the Apache License, Version 2.0.
