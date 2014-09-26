#!/usr/bin/env coffee

{ parse, parseWatch } = require('../index')

parse ->
    @collect "client", -> [
            @dest "_site/assets/css/client.css", ->
                @concatcss ->
                    @less "**/*.less"

            @toDir "_site/images", ->
                @glob 'assets/**/*.png'

            @dest "_site/assets/js/client.js", ->
                @concatjs -> 
                    @livescript "src/assets/**/*.ls"
            ]

    @collect "server", -> 
        @toDir "server/js", ->
            @livescript "src/server/**/*.ls"
        

