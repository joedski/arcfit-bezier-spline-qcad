# ArcfitBezierSpline.NaiveBiarcFitter
# Implementation of my Naïve Biarc Fitting algorithm.
# This only works for convex splines and fails in various ways on splines with inflection points, loops, and cusps.
# The algorithm as defined does not try to best-fit a biarc to a given spline,
# it merely produces a biarc based on the spline's cage without checking
# if there are better possible results.

NaiveBiarcFitter =
	# => Array<RArc|RLine>
	fitSegment: ( splineSegment ) ->
		p0 = splineSegment[ 0 ]
		p3 = splineSegment[ 3 ]

		p0p1 = V.normalize( V.subtract( splineSegment[ 1 ], splineSegment[ 0 ] ) )
		p1p0 = V.negate( p0p1 )
		p1p2 = V.normalize( V.subtract( splineSegment[ 2 ], splineSegment[ 1 ] ) )
		p2p1 = V.negate( p1p2 )
		p3p2 = V.normalize( V.subtract( splineSegment[ 2 ], splineSegment[ 3 ] ) )
		p0p3 = V.normalize( V.subtract( splineSegment[ 3 ], splineSegment[ 0 ] ) )
		p3p0 = V.negate( p0p3 )

		n1p = V.normalize( V.add( p0p1, p1p2 ) )
		n2p = V.normalize( V.add( p3p2, p2p1 ) )
		nt = V.normalize( V.cross( V.cross( p1p2, p1p0 ), p1p2 ) )
		n0 = V.cross( p0p1, V.cross( p0p3, p0p1 ) )
		n3 = V.cross( p3p2, V.cross( p3p0, p3p2 ) )

		pc = @linearIntersection( @lineObjectFromStartAndVector( p0, n1p ), @lineObjectFromStartAndVector( p3, n2p ) );

		if @isPCOutsideOfSegmentCage pc, splineSegment
			return @splitAndFit splineSegment

		c0 = @linearIntersection( @lineObjectFromStartAndVector( p0, n0 ), @lineObjectFromStartAndVector( pc, nt ) );
		c1 = @linearIntersection( @lineObjectFromStartAndVector( p3, n3 ), @lineObjectFromStartAndVector( pc, nt ) );

		# Edge case: If first control point (p0p1) is co-linear with chord (p0p3),
		# this assumes the spline is not reversed.
		# Need to check if the second control point is co-linear, too.
		# Anyway, it seems to work well enough for creating arcs.
		splineDirection = V.cross( p0p3, p0p1 ).getZ()

		splineIsReversed = switch
			when splineDirection > 0 then true
			else false

		[
			@arcFromStartEndCenter p0, pc, c0, splineIsReversed
			@arcFromStartEndCenter pc, p3, c1, splineIsReversed
		]

	splitAndFit: ( splineSegment ) ->
		SplineUtils.splitAndFit splineSegment, 0.5, _.bind( @fitSegment, this )

	isPCOutsideOfSegmentCage: ( pc, splineSegment ) ->
		haveOppositeSigns = ( a, b ) ->
			if a < 0 and b > 0 then true
			else if a > 0 and b < 0 then true
			else false

		# pc is outside of the cage if p0p3 x p0pc
		# is the opposite sign of p0p3 x p0p1 and p0p3 x p0p2
		chord = V.subtract splineSegment[ 3 ], splineSegment[ 0 ]
		p0pc = V.subtract pc, splineSegment[ 0 ]
		p0pcCrossZ = V.cross( chord, p0pc ).getZ()

		p0p1 = V.subtract splineSegment[ 1 ], splineSegment[ 0 ]
		p0p1CrossZ = V.cross( chord, p0p1 ).getZ()

		return true if not RMath.fuzzyCompare( p0p1CrossZ, 0 ) and haveOppositeSigns p0pcCrossZ, p0p1CrossZ

		p0p2 = V.subtract splineSegment[ 2 ], splineSegment[ 0 ]
		p0p2CrossZ = V.cross( chord, p0p1 ).getZ()

		return true if not RMath.fuzzyCompare( p0p2CrossZ, 0 ) and haveOppositeSigns p0pcCrossZ, p0p2CrossZ

		false

	linearIntersection: ( La, Lb ) ->
		upVector = new RVector( 0, 0, 1 )

		vab = V.subtract( Lb.point, La.point )
		nbp = V.cross( Lb.normal, upVector )
		vatb = V.scale( nbp, V.dot( nbp, vab ) )
		natb = V.normalize( vatb )
		vacM = V.magnitude( vatb ) / V.dot( natb, La.normal )
		vac = V.scale( La.normal, vacM )
		pc = V.add( La.point, vac )

		return pc;

	lineObjectFromStartAndVector: ( start, vector ) ->
		point: start
		normal: vector.normalize()

	arcFromStartEndCenter: ( start, end, center, isReversed ) ->
		startRelative = V.fromAToB center, start
		endRelative = V.fromAToB center, end

		radius = V( startRelative ).magnitude()
		startAngle = startRelative.getAngle()
		endAngle = endRelative.getAngle()

		new RArc center, radius, startAngle, endAngle, isReversed