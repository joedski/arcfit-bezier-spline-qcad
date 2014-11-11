###
ArcfitBezierSpline: Converts Bezier Splines into Polylines composed of arcs and line segments
###

# Hax.  Keep QCAD happy when Lodash is checking for existence of global window var
window = window

include '../Modify.js'

# Include other libs...
include './lodash.compat.js'
include './math.js' # lol.
include './cubicroots.js'
include './v.js'

class ArcfitBezierSpline extends Modify
	# hax: QCAD's script engine doesn't like CoffeeScript's extend mechanism.
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

			@__environment__.storage = @__environment__.document.getStorage()

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
	
	applyOperation: ( op ) -> @environment().documentInterface.applyOperation( op )

	beginAction: ( op ) ->
		splineList = @getSelectedSplines()
		polylineList = _( splineList ).map( _.bind( @arcfitSpline, this ) )
		_( splineList ).each ( splineEntity ) -> op.deleteObject splineEntity
		_( polylineList ).each ( polylineEntity ) -> op.addObject polylineEntity
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

		return LineFitter.fitSegment splineSegment if @splineIsLine splineSegment
		return NaiveBiarcFitter.fitSegment splineSegment if @splineIsTooDamnSmall splineSegment
		return @splitAndFitSplineSegment splineSegment if @splineMiddleSegmentIsReversed splineSegment
		return @splitAndFitSplineSegment splineSegment, @getFirstInflectionPointTValue splineSegment if @splineHasInflecitonPoint splineSegment

		shapeList = NaiveBiarcFitter.fitSegment splineSegment

		if @splineIsTooDistant splineSegment, shapeList
			return @splitAndFitSplineSegment splineSegment
		else
			return shapeList

	splitAndFitSplineSegment: ( splineSegment, t ) ->
		SplineUtils.splitAndFit splineSegment, t, _.bind( @arcfitSplineSegment, this )
	
	# ########
	# Tests.
	# ########

	splineIsLine: ( splineSegment ) ->
		# TODO: Make sure control points aren't going out past their end points.
		p3p2 = V.normalize( V.subtract( splineSegment[ 2 ], splineSegment[ 3 ] ) )
		p0p1 = V.normalize( V.subtract( splineSegment[ 1 ], splineSegment[ 0 ] ) )
		p0p3 = V.normalize( V.subtract( splineSegment[ 3 ], splineSegment[ 0 ] ) )
		splineDirection = V.cross( p0p3, p0p1 ).getZ()

		RMath.fuzzyCompare( splineDirection, 0 ) && RMath.fuzzyCompare( V.cross( p0p3, p3p2 ).getZ(), 0 )

	splineIsTooDamnSmall: ( splineSegment ) -> false

	splineIsTooDistant: ( splineSegment ) ->
		# Intent: Test some points for how distant they are from the arc whose angles they're within.
		# Process:
		# Determine number of sample points within spline. (Note, end points are always co-locational.)
		#   Probably based on size threshold?  OR just fixed number?  But at small scales, fixed number is unnecessary.
		# map points:
		#   Check which arc it's inside of
		#   return distance from point to orthogonal projection of point onto arc.
		# compare max of points' distances to threshold value.
		false

	splineMiddleSegmentIsReversed: ( splineSegment ) ->
		# dot middleSegment, chord < 0 => true, else false.
		middleSegment = V.subtract splineSegment[ 2 ], splineSegment[ 1 ]
		chord = V.subtract splineSegment[ 3 ], splineSegment[ 0 ]
		return V.dot( middleSegment, chord ) < 0

	splineHasInflecitonPoint: ( splineSegment ) ->
		# ...?
		# For now, might be splineMiddleSegmentIsReversed && splineCageIsConcave.
		false
	
	# ##################
	# Low Level Implementation
	# ##################

	# Returns a t-value on the spline.
	getFirstInflectionPointTValue: ( splineSegment ) ->
		# return @getPointOnSpline splineSegment, 0.5
		0.5

	getFirstInflectionPoint: ( splineSegment ) ->
		inflectionPointTValue = @getFirstInflectionPointTValue splineSegment

		# We don't care if it's at the end points...
		if 0 < inflectionPointTValue < 1
			@getPointOnSpline splineSegment, inflectionPointTValue
		else
			null

	getPointOnSpline: ( splineSegment, t ) ->
		p01 = V.lerp splineSegment[ 0 ], splineSegment[ 1 ], t
		p12 = V.lerp splineSegment[ 1 ], splineSegment[ 2 ], t
		p23 = V.lerp splineSegment[ 2 ], splineSegment[ 3 ], t
		p0112 = V.lerp p01, p12, t
		p1223 = V.lerp p12, p23, t
		pc = V.lerp p0112, p1223, t
		pc



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
