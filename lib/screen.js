(function(){
  var _, moment, fs, color, ref$, spawn, kill, __q, sh, os, shelljs, blessed, debug, _module;
  _ = require('underscore');
  _.str = require('underscore.string');
  moment = require('moment');
  fs = require('fs');
  color = require('ansi-color').set;
  ref$ = require('child_process'), spawn = ref$.spawn, kill = ref$.kill;
  __q = require('q');
  sh = require('shelljs');
  os = require('os');
  shelljs = sh;
  blessed = require('blessed');
  debug = require('debug')('nmake:screen');
  _.mixin(_.str.exports());
  _.str.include('Underscore.string', 'string');
  _module = function(){
    var iface;
    iface = {
      addChangedFile: function(c){
        return console.log("Changed " + c);
      },
      log: function(c){
        return console.log(c);
      }
    };
    return iface;
  };
  module.exports = _module;
}).call(this);
