"use strict"; 

debug = require('debug')('backends/make')




_module = ->

    printPhonyTarget = (node, names) ->
        let @=node.model
            """ 
            .PHONY: #{@targetName}
            #{@targetName}: #{names * ' '}

            """

    removeProducts = (names) ->
        [ "\t\trm #p" for p in names ]

    printCleanTargets = (tb) ->
        console.log """
        clean:
        #{(removeProducts tb.allProducts) * '\n'}
        """

    printTarget = (name, node) ->
        let @=node.model
            if @builds? and @type in [ "compile", "process", "move" ]
                for c in @builds
                    console.log """

                                #{c.product}: #{c.source} #{c.deps * ' '}
                                      #{c.command}
                                """

            if @builds? and @type in [ "reduce" ] 
                for c in @builds
                    console.log """

                                #{c.product}: #{c.deps * ' '}
                                      #{c.command}
                                """

            console.log """ 
                        .PHONY: #{@targetName}
                        #{@targetName}: #{@products * ' '}

                        """

    iface = { 
        transcript: (tb) ->
            for k,v in tb.phonyTargets
                printPhonyTarget k, v

            for k,v of tb.allTargets
                printTarget(k, v)

            printCleanTargets tb

    }
  
    return iface
 
module.exports = _module()

