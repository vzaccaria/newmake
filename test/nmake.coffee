#!/usr/bin/env coffee

{ parse, parseWatch } = require('../index')

parse ->
    @collect "client", -> [
            @dest "_site/assets/css/client.css", ->
                @concatcss ->
                    @less "src/**/*.less"

            @toDir "_site/assets/images", { strip: 'src/assets/images' },  ->
                @glob 'src/assets/**/*.png'

            @dest "_site/assets/js/client.js", ->
                @concatjs -> 
                    @livescript "src/assets/**/*.ls"
            ]

    @collect "server", -> 
        @toDir "server/js", { strip: 'src/server' },  ->
            @livescript "src/server/**/*.ls"

    @cleanupTargets()
        

