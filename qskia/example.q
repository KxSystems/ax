skia:use`skia
skia.init[.Q.rp "::../"] // Path to this directory, skia picks up fonts
s:skia.new[400;400]
skia.setStrokeColour[s;0x0 sv"x"$255 0 0 0]
skia.setFillColour[s;0x0 sv"x"$255 255 255 255]
skia.setFontSize[s;36];
skia.setFontFace[s;"regular";1b;1b]
skia.addText[s;20;40;"Hello from KDB-X!"]
skia.setFillColour[s;0x0 sv"x"$255 255 0 0]
skia.addCircle[s;200;200;100]
h:hopen `:example.png
h skia.toPNG[s];
hclose h
\\
