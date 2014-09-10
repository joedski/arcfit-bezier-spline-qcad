###
V: A small library to wrap around RVector to make common operations easier to write.
Unlike RVector, all operations can be assumed to produce a new vector.
###

# include './lodash.js' if not _

do ->
	root = switch
		when (typeof window != 'undefined') then window
		else this

	class V
		clone = ( rvector ) ->
			if rvector
				new RVector rvector.getX(), rvector.getY(), rvector.getZ(), rvector.isValid()

		unwrap = ( vector ) ->
			if vector instanceof V then vector.__wrapped__
			else vector

		chainable = ( fn ) ->
			( args... ) ->
				args.unshift @__wrapped__
				returnValue = fn.apply this, args
				if @__chain__ then new V( returnValue, @__chain__ )
				else returnValue

		# Unchained functions
		@chain = ( a ) -> new V( a ).chain()
		# These functions all return RVector, not V.
		@clone = ( a ) -> clone a
		# These ops return new vectors.
		@add = ( a, b ) -> unwrap( a ).operator_add( b )
		@subtract = ( a, b ) -> unwrap( a ).operator_subtract( b )
		@fromAToB = ( a, b ) -> V( b ).subtract( unwrap a )
		@cross = ( a, b ) -> RVector.getCrossProduct unwrap( a ), unwrap( b )
		@dot = ( a, b ) -> RVector.getDotProduct unwrap( a ), unwrap( b )
		@negate = ( a ) -> unwrap( a ).getNegated()
		@lerp = ( a, b, t = 0.5 ) -> V( a ).chain().scale( 1 - t ).add( V( b ).scale( t ) ).value()
		# These do not return new vectors in the QCAD API, so we have to clone here.
		@normalize = ( a ) -> V( a ).clone().normalize()
		# RVector#scale() => RVector, so we don't need to store a temporary variable.
			# s may be either a float or RVector.
			# NOTE: In the C++ implementation, RVector#scale() takes an optional 3rd argument.
			# I guess that's not acceptable here?
		@scale = ( a, s, c = null ) -> V( a ).clone().scale( unwrap( s ) )
		# These return non-vector values.
		@magnitude = ( a ) -> unwrap( a ).getMagnitude()

		# Actual method definitions
		constructor: ( rvector, chainAll ) ->
			if this instanceof V
				@__chain__ = !!chainAll
				@__wrapped__ = rvector
				this
			else
				if rvector and (typeof rvector == 'object') and rvector.hasOwnProperty '__wrapped__'
					return rvector
				else
					return new V rvector

		chain: ->
			@__chain__ = true
			this

		clone: chainable clone
		add: chainable @add
		subtract: chainable @subtract
		cross: chainable @cross
		dot: chainable @dot
		negate: chainable @negate
		lerp: chainable @lerp
		normalize: chainable @normalize
		scale: chainable @scale
		# This doesn't return a wrapped value...
		# magnitude: -> magnitude @__wrapped__
		magnitude: do ( consMagnitude = @magnitude ) -> -> consMagnitude @__wrapped__

	root.V = V
