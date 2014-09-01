arcfit-bezier-spline-qcad
=========================

A rudimentary script to arcfit bezier splines, written in coffeescript against the QCAD Script API.

Nothing in this is super complex math wise, just a bit of fun with vectors.

The goal of this project is to write understandable code, not speed-efficient code.  This is why there is a glut of functions everywhere because functional programming f-yeah.

Notes
-----

Currently, the project statically compiles lodash and some other crud into a single file, which should go into the QCAD scripts folder thus:

    scripts/Modify/ArcfitBezierSpline/ArcfitBezierSpline.js

If for some reason I start making other scripts, then I might require those be installed in a separate folder just inside scripts to share code.