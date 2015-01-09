"use strict";

var _require = require("./tree");

var parse = _require.parse;
var transcript = _require.transcript;


var linkCmd = function (__) {
  return "minify " + __.source + " -o " + __.product;
};
var linkProd = function (__) {
  return "minified(" + __.source + ")";
};
var ccCmd = function (__) {
  return "cc " + __.source + " -o " + __.product;
};
var ccProd = function (__) {
  return "prodOf(" + __.source + ")";
};

var tb = parse(function (_) {
  _.collect("x", function (_) {
    _.processFiles(linkCmd, linkProd, function (_) {
      _.collect("y", function (_) {
        _.compileFiles(ccCmd, ccProd, "B.c");
        _.compileFiles(ccCmd, ccProd, "D.c", ["E.h"]);
      });
    });
    _.compileFiles(ccCmd, ccProd, "x.c");
  });
});

transcript(tb);

