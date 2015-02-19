"use strict"; 

debug = require('debug')('backends/make')

_module = ->

    printPhonyTarget = (name, names) ->
            """ 
            .PHONY: #{name}
            #{name}: #{names * ' '}

            """

    printPhonySeqTarget = (name, names) ->
            """ 
            .PHONY: #{name}
            #{name}: 
            #{['\tmake '+n for n in names ] * '\n'}

            """

    printTarget = (name, deps, command) ->
            """
            #{name}: #{deps}
            \t#{command}

            """

    iface = { 
        transcript: (f) ->

            for k in f.getPhonyTargetNames!
                if not f.isPhonyTargetSequential(k)
                    console.log(printPhonyTarget(k, f.getTargetDepsAsNames(k)))
                else 
                    console.log(printPhonySeqTarget(k, f.getTargetDepsAsNames(k))) 


            for k in f.getActualTargetNames!
                console.log printTarget(k, f.getTargetDepsAsNames(k), f.getTargetCreationCommand(k))

    }
  
    return iface
 
module.exports = _module()

