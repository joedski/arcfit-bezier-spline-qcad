// Equations: http://planetmath.org/cubicformula
// I then isolated the common parts to make calculation more efficient and less annoying to write.
// This is probably pretty slow due to using math.js rather than hard coding all the calculations.
// On the other hand, given how common imaginary terms will be in these calculations, it's probably
// about the same as what I would have written by hand, only better written and battle tested.

// Exports 2 methods:
// cubicRoots.calc( p, q, r, s )
//     Calculates the 3 zeros of the cubic equation with the form of px^3 + qx^2 + rx + s = 0.
// cubicRoots.calcReal( p, q, r, s )
//     The same as cubicRoots.calc, except that it only returns real roots.
//     There may be 1, 2, or 3 real roots
//     Well, there will probably be 1 or 3, and in the case of 2,
//     it's 3 roots where 2 of them are the same.

// namespace.
var cubicRoots = {};

(function initCubicRoots() {
	// for px^3 + qx^2 + rx + s = 0
	cubicRoots.calc = function cubicRoots( p, q, r, s ) {
		// convert to x^3 + ax^2 + bx + c = 0
		var
			a = q/p,
			b = r/p,
			c = s/p;

		// -a/3 + {1, -(1+i√3) / 2, (-1+i√3) / 2} * ParenGroupPlus + {1, (-1+i√3) / 2, -(1+i√3) / 2} * ParenGroupMinus
		// Bit + UnityRootA * ParenGroupPlus + UnityRootB * ParenGroupMinus
		// ParenGroupPlus = cbrt( (WholePart + SquareRootPart) / 54 )
		// ParenGroupMinus = cbrt( (WholePart - SquareRootPart) / 54 )
		// WholePart = -2a^3 + 9ab - 27c
		// SquareRootPart = sqrt( (2a^3 - 9ab + 27c)^2 + 4(-a^2 + 3b)^3 )
		//                = sqrt( (-WholePart)^2 + 4(-a^2 + 3b)^3 )

		var
			wholePart = calcWholePart( a, b, c ),
			squareRootPart = calcSquareRootPart( a, b, c, wholePart ),
			parenGroupPlus = calcParenGroup( wholePart, squareRootPart, 1 ),
			parenGroupMinus = calcParenGroup( wholePart, squareRootPart, -1 ),
			bitOnFront = (-a) / 3;

		var roots = [
			calcRoot( bitOnFront, 1, parenGroupPlus, 1, parenGroupMinus ),
			calcRoot( bitOnFront, unityRoot2nd, parenGroupPlus, unityRoot3rd, parenGroupMinus ),
			calcRoot( bitOnFront, unityRoot3rd, parenGroupPlus, unityRoot2nd, parenGroupMinus )
		];
	};

	cubicRoots.calcReal = function realCubicRoots( p, q, r, s ) {
		var roots = cubicRoots( p, q, r, s ),
			realRoots = [];

		var i, length, root;

		for( i = 0, length = roots.length; i < length; ++i ) {
			if( math.equal( root.im, 0 ) ) {
				realRoots.push( root.re ); // math.js uses native JS Numbers unless configured otherwise.
			}
		}
	};

	// Note: Using math.eval is probably slow.
	// Although, if it's compiled then it's probably just as fast as writing out the method calls manually.
	var
		wholePartExpr = math.compile( '-2 * a^3 + 9 * a * b - 27 * c' ),
		squareRootPartExpr = math.compile( 'sqrt( (-w)^2 + 4(-a^2 + 3b)^3 )' ),
		parenGroupExpr = math.compile( 'dotPow( (w + s * r), 1/3 )' ),
		unityRoot1st = math.eval( '1' ),
		unityRoot2nd = math.eval( '-(1 + i * sqrt( 3 )) / 2' ),
		unityRoot3rd = math.eval( '(-1 + i * sqrt( 3 )) / 2' ),
		rootExpr = math.compile( 'b + u * p + v * q' );

	// WholePart = -2a^3 + 9ab - 27c
	function calcWholePart( a, b, c ) {
		return wholePartExpr.eval({
			a: a,
			b: b,
			c: c
		});
	}

	// SquareRootPart = sqrt( (2a^3 - 9ab + 27c)^2 + 4(-a^2 + 3b)^3 )
	//                = sqrt( (-WholePart)^2 + 4(-a^2 + 3b)^3 )
	function calcSquareRootPart( a, b, c, wholePart ) {
		return squareRootPartExpr.eval({
			a: a,
			b: b,
			c: c,
			w: wholePart
		});
	}

	// ParenGroupPlus = cbrt( (WholePart + SquareRootPart) / 54 )
	// ParenGroupMinus = cbrt( (WholePart - SquareRootPart) / 54 )
	function calcParenGroup( wholePart, squareRootPart, sign ) {
		return parenGroupExpr.eval({
			w: wholePart,
			r: squareRootPart,
			s: sign
		});
	}

	function calcRoot( bitOnFront, unityRootA, parenGroupPlus, unityRootB, parenGroupMinus ) {
		return rootExpr.eval({
			b: bitOnFront,
			u: unityRootA,
			p: parenGroupPlus,
			v: unityRootB,
			q: parenGroupMinus
		});
	}
}());
