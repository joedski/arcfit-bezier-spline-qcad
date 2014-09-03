exports.config =
	# See http://brunch.io/#documentation for docs.
	paths:
		public: 'public/ArcfitBezierSpline'
		watched: [ 'app', 'lib', 'test', 'vendor', 'bower_components' ]
	conventions:
		ignored: [
			( path ) -> /^bower_components[\\/]lodash[\\/]/.test( path ) && not /lodash\.compat\.js$/.test( path )
		]
		vendor: [
			/^vendor[\\/]/
		]
		assets: [
			/^bower_components[\\/]lodash[\\/]dist/
		]
	files:
		javascripts:
			joinTo:
				'v.js': /(^|[\\/])v\.[a-zA-Z0-9]+$/
				'ArcfitBezierSpline.js': /^app[\\/]/
			order:
				after: [
					/^app[\\/]/
				]
	# QCAD sections off scripts by itself.
	modules:
		wrapper: false
		definition: false
