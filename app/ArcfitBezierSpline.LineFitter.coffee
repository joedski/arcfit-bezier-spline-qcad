LineFitter =
	# => Array<RLine>
	fitSegment: ( splineSegment ) ->
		[ @lineFromStartEnd splineSegment[ 0 ], splineSegment[ 3 ] ]

	lineFromStartEnd: ( start, end ) ->
		new RLine start, end