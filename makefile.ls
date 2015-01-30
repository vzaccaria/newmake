#!/usr/bin/env lsc 


{ parse, add-plugin } = require('newmake')

parse ->
    @collect "all", ->
        @command-seq -> [
            @toDir "./lib", { strip: "src" }, -> [
                @livescript "./src/*.ls"
            ]
            @cmd "cp ./lib/index.js ."
        ]

    @collect "test", -> 
        @command-seq -> [
            @cmd "./test/test1.sh"
            @cmd "./test/test2.sh"
        ]

    for l in ["major", "minor", "patch"]
        @collect "release-#l", -> [
            @cmd "./node_modules/.bin/xyz --increment #l"
        ]
