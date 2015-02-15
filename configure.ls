#!/usr/bin/env lsc 


{ parse, add-plugin } = require('newmake')

parse ->

    @add-plugin "es6", (g) ->
        @compile-files( (-> "6to5 #{it.orig-complete} -o #{it.build-target}" ) , ".js", g)


    @collect "all", ->
        @command-seq -> [
            @toDir "./lib", { strip: "src" }, -> [
                @es6 "src/treeTest.js"
                @livescript "src/*.ls"
            ]
            @cmd "cp ./lib/index.js ."
        ]

    @collect "test", -> 
        @command-seq -> [
            @make \all
            @cmd "node lib/treeTest.js"
        ]

