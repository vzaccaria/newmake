"use strict";

var _require = require("./tree");

var parse = _require.parse;
var getTargets = _require.getTargets;
var transcript = _require.transcript;


var tb = parse(function (_) {
  _.collect("x", function (_) {
    _.processFiles("link", ".x", function (_) {
      _.collect("y", function (_) {
        _.compileFiles("cc", "B.c");
        _.compileFiles("cc", "D.c", ["E.h"]);
      });

      _.compileFiles("cc", "x.c");
    });
  });
});

transcript(tb);

