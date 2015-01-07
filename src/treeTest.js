"use strict"; 

var { parse, getTargets, transcript } = require('./tree')

var tb = parse(_ => {

    _.collect("x", _ => {

    	_.processFiles("link", ".x", _ => {

    	        _.collect("y", _ => {

    	            _.compileFiles("cc", "B.c");
    	            _.compileFiles("cc", "D.c", [ "E.h" ]); 

    	        });

    			_.compileFiles("cc", "x.c");

    	})
	})
})

transcript(tb)