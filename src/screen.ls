
_               = require('underscore')
_.str           = require('underscore.string');
moment          = require 'moment'
fs              = require 'fs'
color           = require('ansi-color').set
{ spawn, kill } = require('child_process')
__q             = require('q')
sh              = require('shelljs')
os              = require('os')
shelljs         = sh
blessed = require('blessed')
debug = require('debug')('nmake:screen')

_.mixin(_.str.exports());
_.str.include('Underscore.string', 'string');


_module = ->
    # screen = blessed.screen()

    # style =  {
    #     fg: 'white',
    #     bg: 'black',
    #     border: {
    #       fg: '#f0f0f0'
    #     },
    #     hover: {
    #       bg: 'green'
    #     }
    # }

    # changed-box = { top: '0%', left: '50%', width: '50%', height: '100%' }
    # changed-box.style = style


    # cbox = blessed.box(changed-box)

    # screen.append(cbox)

    # screen.key ['escape', 'q', 'C-c'], ->
    #   process.exit(0);

    # screen.render()
          
    iface = { 
        add-changed-file: (c) ->
            console.log "Changed #c"
            # cbox.setContent(c)
            # screen.render()
        log: (c) ->
            console.log c

    }
  
    return iface
 
module.exports = _module


