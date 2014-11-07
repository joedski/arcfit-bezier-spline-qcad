# Point this to your QCAD installation's script directory.
# For Macs, this is usually /Applications/QCAD.app/Contents/Resources/scripts
# If you installed it in your user-specific Applications folder, modify the path appropriately.
qcadScriptDir = "/Applications/QCAD.app/Contents/Resources/scripts"

ncpCall = ( source, destination ) ->
	"""node -e 'require( "ncp" ).ncp( "#{ source }", "#{ destination }",""" +
		"""function( error ) { if( error ) {""" +
		"""return console.log( "Error trying to copy #{ source } to #{ destination }:" ); console.error( error ); } } );'"""

exports.config =
	# See http://brunch.io/#documentation for docs.
	paths:
		public: 'public/ArcfitBezierSpline'
		watched: [ 'app', 'lib', 'test', 'vendor', 'bower_components' ]
	conventions:
		ignored: [
			( path ) -> /^bower_components[\\/]lodash[\\/]/.test( path ) && not /lodash\.compat\.js$/.test( path )
			( path ) -> /^bower_components[\\/]mathjs[\\/]/.test( path ) && not /math\.js$/.test( path )
		]
		vendor: [
			/^vendor[\\/]/
		]
		assets: [
			/^bower_components[\\/]lodash[\\/]dist/
			/^bower_components[\\/]mathjs[\\/]dist/
		]
	files:
		javascripts:
			joinTo:
				'v.js': /(^|[\\/])v\.[a-zA-Z0-9]+$/
				'cubicroots.js': /(^|[\\/])cubicroots\.[a-zA-Z0-9]+$/
				'ArcfitBezierSpline.js': /^app[\\/]/
			order:
				after: [
					/^app[\\/]/
				]
	# QCAD sections off scripts by itself.
	modules:
		wrapper: false
		definition: false

	plugins:
		afterBrunch: [
			ncpCall( "public/ArcfitBezierSpline", "#{qcadScriptDir}/Modify/ArcfitBezierSpline" )
		]

		autoReload:
			enabled: false