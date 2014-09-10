###
ArcfitBezierSpline: Converts Bezier Splines into Polylines composed of arcs and line segments
###

window = window

include '../Modify.js'

# Include other libs...
include './lodash.compat.js'
include './v.js'

class ArcfitBezierSpline extends Modify
	# hax
	# QCAD's script engine doesn't like CoffeeScript's extend mechanism.
	@prototype = new Modify

	@init = ( basePath ) ->
		action = new RGuiAction( qsTr( "Arc-Fit Bezier Spline" ), RMainWindowQt.getMainWindow() )

		@pathTo = ( file ) -> [ basePath, file ].join '/'

		action.setRequiresDocument true
		action.setScriptFile this.pathTo( "ArcfitBezierSpline.js" )
		# action.setIcon this.pathTo( "ArcfitBezierSpline.svg" )
		action.setStatusTip qsTr( "Convert a B-Spline repsesenting a multi-piece Bezier curve into a Polyline." )
		action.setDefaultShortcut new QKeySequence( "x,a" )
		action.setDefaultCommands [ "arcfitsplinebezier", "arcfitbezier" ]
		# I should probably determine a proper sort order at some point...
		action.setSortOrder 4100

		# args: action, interface, addToMenu, addToToolBar, addToCadToolBar, addSeparatorBefore = false
		# You'll probably want an icon if you want to have addToToolBar=true.
		EAction.addGuiActionTo action, Modify, true, false, false
		return

	@getPreferenceCatagory = -> [ qsTr( 'Modify' ), qsTr( 'ArcFitSpline' ) ]

	@defaultOptions =
		tolerance: 0.1 #units



	# ##################
	# Method definitions
	# ##################

	# A cached object which holds certain environment vars pertinent to the current action.
	__environment__: null

	environment: ->
		unless @__environment__?
			@__environment__ =
				documentInterface: this.getDocumentInterface()
				document: this.getDocument()
				storage: null

		@__environment__

	clearEnvironment: -> @__environment__ = null; this

	options: ( setOptions ) ->
		unless __options__?
			@__options__ = _.defaults {}, ArcfitBezierSpline.defaultOptions

		if setOptions?
			@__options__ = _.extend @__options__, setOptions

		@__options__

	clearOptions: -> @__options__ = null; this

	# ##################
	# Main Control Flow
	# These methods are defined by the QCAD API.
	# ##################

	beginEvent: ->
		super
		op = new RMixedOperation()
		@applyOperation @beginAction op
		@terminate()

	terminate: ->
		@applyDebugOperations()
		@clearEnvironment()
		@clearOptions()
		super

	# ##################
	# High Level Implementation
	# ##################

	beginAction: ( op ) ->
		splineList = @getSelectedSplines()
		polylineList = _( splineList ).map( _.bind( @arcfitSpline, this ) )
		_( splineList ).each ( splineEntity ) -> op.deleteObject splineEntity
		_( polylineList ).each( polylineEntity ) -> op.addObject polylineEntity
		op

	getSelectedSplines: ->
		environment = @environment()
		selectedEntities = _( environment.document.querySelectedEntities() ).map ( id, idIndex ) ->
			environment.document.queryEntity id
		_( selectedEntities ).filter isSplineEntity

	arcfitSpline: ( splineEntity, index, splineList ) ->
		newShapes = []
		# Even though QCAD only uses B-Splines, this seems to be 3 for cubic bezier splines...?
		degree = splineEntity.getDegree()
		pointList = splineEntity.getControlPoints()
		pointCount = pointList.length
		startIndexList = _.range 0, pointCount - 1, degree
		splineSegmentPointLists = _( startIndexList ).map ( startIndex, segmentIndex ) ->
			pointList.slice startIndex, startIndex + degree + 1

		@createPolylineFromShapes _( splineSegmentPointLists ).reduce(
			( newShapes, splineSegment ) => newShapes.concat @arcfitSplineSegment splineSegment
			newShapes
		)

	createPolylineFromShapes: ( shapeList ) ->
		polylineEntity = new RPolylineEntity( @environment().document, new RPolylineData() )

		return polylineEntity if shapeList.length == 0

		_( shapeList ).each ( shapeData ) ->
			bulge = switch
				when isOfType shapeData, RArc then bulge = shapeData.getBulge()
				else 0
			polylineEntity.appendVertex shapeData.getStartPoint(), bulge

		polylineEntity.appendVertex _.last( shapeList ).getEndPoint(), 0

		polylineEntity

	arcfitSplineSegment: ( splineSegment ) ->
		degree = splineSegment.length
		shapeList

		return @linefitSplineSegment splineSegment if @splineIsLine splineSegment
		return @biarcfitSplineSegment splineSegment if @splineIsTooDamnSmall splineSegment
		return @splitAndFitSplineSegment splineSegment if @splineMiddleSegmentIsReversed splineSegment
		return @splitAndFitSplineSegment splineSegment, @getFirstInflectionPoint splineSegment if @splineHasInflecitonPoint splineSegment

		shapeList = @biarcfitSplineSegment splineSegment

		if @splineIsTooDistant splineSegment, shapeList
			return @splitAndFitSplineSegment splineSegment
		else
			return shapeList

	splitAndFitSplineSegment: ( splineSegment, t = 0.5 ) ->
		_( @splitSpline splineSegment, t ).chain()
			.map( _.bind( @arcfitSplineSegment, this ) )
			.flatten( true )
			.value()

	# Split a spline at t into two splines.
	# => Array<Array<RVector>>
	splitSpline: ( splineSegment, t = 0.5 ) ->
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
	
	# Tests.

	# Currently, all stubs.
	splineIsLine: ( splineSegment ) -> false
	splineIsTooDamnSmall: ( splineSegment ) -> false
	splineIsTooDistant: ( splineSegment ) -> false
	splineMiddleSegmentIsReversed: ( splineSegment ) -> false
	splineHasInflecitonPoint: ( splineSegment ) -> false
	splineIsTooDistant: ( splineSegment ) -> false # false here means it only iterates once.
	
	# ##################
	# Low Level Implementation
	# ##################

	getFirstInflectionPoint: ( splineSegment ) ->
		return @getPointOnSpline splineSegment, 0.5

	getPointOnSpline: ( splineSegment, t ) ->
		p01 = V.lerp splineSegment[ 0 ], splineSegment[ 1 ], t
		p12 = V.lerp splineSegment[ 1 ], splineSegment[ 2 ], t
		p23 = V.lerp splineSegment[ 2 ], splineSegment[ 3 ], t
		p0112 = V.lerp p01, p12, t
		p1223 = V.lerp p12, p23, t
		pc = V.lerp p0112, p1223, t
		pc

	# => Array<RLine>
	linefitSplineSegment: ( splineSegment ) ->
		[ @lineFromStartEnd splineSegment[ 0 ], splineSegment[ 3 ] ]

	lineFromStartEnd: ( start, end ) ->
		new RLine start, end

	biarcfitSplineSegment: ( splineSegment ) ->
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
		c0 = @linearIntersection( @lineObjectFromStartAndVector( p0, n0 ), @lineObjectFromStartAndVector( pc, nt ) );
		c1 = @linearIntersection( @lineObjectFromStartAndVector( p3, n3 ), @lineObjectFromStartAndVector( pc, nt ) );

		splineDirection = V.cross( p0p3, p0p1 ).getZ()

		splineIsReversed = switch
			when splineDirection > 0 then true
			else false

		[
			@arcFromStartEndCenter p0, pc, c0, isSplineReversed
			@arcFromStartEndCenter pc, p3, c1, isSplineReversed
		]

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

# ####################
# Debug
# ####################

	debugOp: -> @__debugOp__ = new RMixedOperation() if not @__debugOp__

	applyDebugOperations: ->
		if @__debugOp__
			@environment().documentInterface.applyOperation @__debugOp__
			@__debugOp__ = null

	# Colors don't seem to work?  I must doing something wrong here.
	debugPoint: ( vec, options ) ->
		options = _.defaults( options || {}, {
			color: null
		})

		entity = new RPointEntity(
			@environment().document
			new RPointData( vec )
		)

		if options.color
			entity.setColor new RColor options.color[ 0 ], options.color[ 1 ], options.color[ 2 ]

		@debugOp().addObject entity

	debugVector: ( start, vec, options ) ->
		options = _.defaults( options || {}, {
			color: null
			magnitude: null
		})

		if options.magnitude
			vec = V( vec ).clone()
			vec.setMagnitude2d( options.magnitude )

		entity = new RLineEntity(
			@environment().document
			new RLineData( start, V( start ).add( vec ) )
		)

		if options.color
			entity.setColor new RColor options.color[ 0 ], options.color[ 1 ], options.color[ 2 ]

		@debugOp().addObject entity

	debugLineSegment: ( start, end, options ) ->
		options = _.defaults( options || {}, {
			color: null
		})

		entity = new RLineEntity(
			this.environment.document
			new RLineData( start, end )
		)

		if options.color
			entity.setColor new RColor options.color[ 0 ], options.color[ 1 ], options.color[ 2 ]

		@debugOp.addObject entity
