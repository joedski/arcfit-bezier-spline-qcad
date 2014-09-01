exports.config =
	# See http://brunch.io/#documentation for docs.
	paths:
		watched: [ 'app', 'test', 'vendor', 'bower_components' ]
	conventions:
		ignored: [
			( path ) -> /lodash.*\.js$/.test( path ) && not /lodash\.compat\.js$/.test( path )
		]
		vendor: [
			/vendor[\\/]/
			/bower_components[\\/]/
		]
	files:
		javascripts:
			joinTo: 'ArcfitBezierSpline/ArcfitBezierSpline.js'
			order:
				after: [
					/^app[\\/]/
				]
	modules:
		wrapper: false
		definition: false
