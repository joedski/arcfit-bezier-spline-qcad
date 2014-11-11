# This says SplineUtils but really it includes anything that might be used by
# more than one module here.

SplineUtils =
	# Split a spline at t into two splines.
	# => Array<Array<RVector>>
	split: ( splineSegment, t = 0.5 ) ->
		# this shares code with getPointOnSpline.
		# Unfortunately, this requires intermediate points.
		# Fortunately, bezier splines are just a bunch of lerps.
		p01 = V.lerp splineSegment[ 0 ], splineSegment[ 1 ], t
		p12 = V.lerp splineSegment[ 1 ], splineSegment[ 2 ], t
		p23 = V.lerp splineSegment[ 2 ], splineSegment[ 3 ], t
		p0112 = V.lerp p01, p12, t
		p1223 = V.lerp p12, p23, t
		pc = V.lerp p0112, p1223, t

		[
			[ splineSegment[ 0 ], p01, p0112, pc ]
			[ pc, p1223, p23, splineSegment[ 3 ] ]
		]

	# Be sure to bind fitterFn if you need a specific context,
	# EG if fitterFn is an object method.
	splitAndFit: ( splineSegment, t, fitterFn ) ->
		_( @split splineSegment, t ).chain()
			.map( fitterFn )
			.flatten( true )
			.value()
