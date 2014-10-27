#!/usr/bin/env coffee

{ parse } = require('../../index')

a = (m) ->
    "_site/assets/#{m}"

s = (m) ->
    "src/assets/#{m}"

parse ->
    @collect "all", -> [
        @collect "client", -> [

            @dest a("css/client.css"), ->
                @concatcss ->
                    @less "src/**/*.less"

            @toDir a("images"), { strip: s('images') },  ->
                @copy 'src/assets/**/*.png'

            @dest a("index.html"), ->
                @copyTarget a("html/index.html")

            @dest a("js/client.js"), ->
                @minifyjs ->
                    @concatjs -> 
                            @livescript s("**/*.ls")

            @toDir a("html"), { strip: s("views") }, -> 
                @jade s("views/index.jade"), a("views/base.jade")
            ]

        @collect "server", -> 
            @toDir "_site/server/js", { strip: 'src/server' },  ->
                @livescript "src/server/**/*.ls"
    ]

    @collect "clean", -> [
            @removeAllTargets()
        ]        

    @testServer = (it) -> 
        @cmd("mocha -C --bail -t 5000 -R min #{s it}")

    @collect "test", -> [
            @testServer "/app-test.js"
            @testServer "/test/acl/acl-test.js"
            @testServer "/core/job-management/job-manager-test.js"
        ]
