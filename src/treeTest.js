"use strict"; 

var { parse, transcript } = require('./tree')

var linkCmd  = __ => `minify ${__.source} -o ${__.product}`
var linkProd = __ => `minified(${__.source})`
var ccCmd    = __ => `cc ${__.source} -o ${__.product}`
var ccProd   = __ => `prodOf(${__.source})`

var tb = parse(_ => {
    _.collect("x", _ => {
        	_.processFiles(linkCmd, linkProd, _ => {
        	        _.collect("y", _ => {
        	            _.compileFiles(ccCmd, ccProd, "B.c");
        	            _.compileFiles(ccCmd, ccProd, "D.c", [ "E.h" ]);
        	        });
	        });
        	_.compileFiles(ccCmd, ccProd, "x.c");
	})
})

transcript(tb)