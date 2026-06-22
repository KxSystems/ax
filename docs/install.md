# ax kdb-x installation

[`graphics.q`](../ax/graphics.q) and [`qdoc.q`](../ax/qdoc.q) is written as a module, under kdb-x's module framework. 
Though modules can be loaded from anywhere if added to your `$QPATH`, we recommend installing under a `kx` folder within your `$QPATH`. This is to avoid name clashes with other user defined modules, as well as providing a name for other KX modules to cross reference each other.

## Installing a Release

It is recommended that a user install this module through a release. 

[Download a release](https://github.com/KxSystems/ax/releases) and then unzip to your module directory. The following example assumes the default install location for KDB-X.

```
unzip ax-l64.zip -d ~/.kx/mod
```

## Installing from Source

```bash
git clone https://github.com/KxSystems/ax.git
cd ax
```

After following the build instructions, move `ax` into your module directory, under `kx`. The following example assumes the default install location for KDB-X.

```bash
mkdir -p ~/.kx/mod/kx
cp -r ax ~/.kx/mod/kx/
```


## Next Steps

Now from anywhere you can import ggplot and qdocs.

```q
q)([gg;qp]):use`kx.ax.graphics
q)t : ([]x:5 * til 45; y: til 45; z: 45?`a`b`c)
q)qp.png[`:p.png;500;500] qp.point[t; `x; `y; ::] // Creates a PNG of a straight line
`:p.png
```

```q
q)([qd]):use`kx.ax.qdoc
// Create file for qdoc
q)`:foo.q 0: ("// @kind function"; "// @fileoverview Function returns the sum of two numbers as an integer"; "// @param x {long} First parameter "; "// @param y {long} Second parameter"; "// @return {int} Sum of the parameters"; "add: {[x; y] "; "    \"i\"$x + y"; "    };"; ""; "// @kind data"; "// @fileoverview Static value of pi"; "PI: 3.14159;")
q)qd.doc[::] `:foo.q
out    | `:/tmp/out/md
md     | +`file`name`kind`module`category`subcategory`content!(`Global.md`Global.md;`./README`add;`readme`function;`Global`;`Global`Global;``;("";"## add\n\nFunction returns the sum of two numbers as an integer\n\n**Parameters:**\n\n|Name|Type|Description|\n|---|---..
error  | +`ref`qdType`errorType`error!(`s#`symbol$();();`symbol$();())
doctest| +`ref`test`success`result`error!(`symbol$();();`boolean$();();())
// markdown output saved under out/
```


You're ready to check out some of the examples and documentation for [GGPlot](https://code.kx.com/analyst/libraries/grammar-of-graphics/) and [qDoc](https://code.kx.com/developer/libraries/documentation-generator/)
