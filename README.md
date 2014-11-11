arcfit-bezier-spline-qcad
=========================

A rudimentary (well, maybe not) script to arcfit bezier splines, written in coffeescript against the QCAD Script API.

Nothing in this is super complex math wise, just a bit of fun with vectors.  (I lied, the inflection point thingy uses a cubic solver.)

The goal of this project is to write understandable code, not speed-efficient code.  This is why there is a glut of functions everywhere because functional programming f-yeah.

WELL this bloated in size far more than I meant it to but at some point I'll make a thing which just wraps QCAD's native complex number class and wraps around that in a similar way to V wrapping around QCAD's Vector3 class.  I'll probably call it C because then I don't have to type as much.  BUT FOR NOW THIS USES MATH.JS.  Horp.

Notes
-----

This may crash QCAD's poor lil non-V8 JS engine.  (CoffeeScript's idea of inheritance already causes issues without tweaking...)  Especially the Math.js thingy.  I should probably replace that sooner than later.

Ah, it seems QCAD doesn't have a Complex Number class exposed to JS.  Alas!

Currently this generates polyline entities, however it seems certain pieces of software such as Sketchup and EasyCut don't like polylines for whatever reason.  It could also be that Sketchup just doesn't like importing arcs, which is strange but whatever.  Unless Sketchup isn't a SCAD editor at all, which it might not be.

I also haven't actually experimented much with how QCAD acts with polylines so, if it turns out to be more convenient to just have already separate shapes than it does to have polylines, then it'll just push out a bunch of shapes.  I'm mainly concerned with trimming and extending.

Also, some things may already be implemented in QCAD's library of miscellaneous maths but I'm too headstrong to look them up and, as much as I try to outsource the actual development of math algorithms, I also enjoy doing the ones I can.

Test Cases
----------

- Simple Convex Splines: __Pass__
- Convex Splines with One Zero-Length Control Handle: __Fail__
- Lines: __Pass__, I think.  QCAD or Illustrator seems to be converting any shape made entirely of plain lines into Polylines.
- Splines with Inflection Points: __Fail__, sometimes with interesting results.
