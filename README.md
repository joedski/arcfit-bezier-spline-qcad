arcfit-bezier-spline-qcad
=========================

A rudimentary script to arcfit bezier splines, written in coffeescript against the QCAD Script API.

Nothing in this is super complex math wise, just a bit of fun with vectors.

The goal of this project is to write understandable code, not speed-efficient code.  This is why there is a glut of functions everywhere because functional programming f-yeah.

WELL this bloated in size far more than I meant it to but at some point I'll make a thing which just wraps QCAD's native complex number class and wraps around that in a similar way to V wrapping around QCAD's Vector3 class.  I'll probably call it C because then I don't have to type as much.  BUT FOR NOW THIS USES MATH.JS.  Horp.

Notes
-----

This may crash QCAD's poor lil non-V8 JS engine.  (CoffeeScript's idea of inheritance already causes issues without tweaking...)  Especially the Math.js thingy.  I should probably replace that sooner than later.
