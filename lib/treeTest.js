"use strict";

var _require = require("./tree");

var parse = _require.parse;


var webPack = require("./packs/web");
var _require2 = require("./backends/make");

var transcript = _require2.transcript;




var tb = parse(function (_) {
  _.addPack(webPack);

  _.collect("all", function (_) {
    _.mirrorTo("./lib", {
      strip: "src/"
    }, function (_) {
      _.toFile("src/pippo.js", function (_) {
        _.concat(function (_) {
          _.collect("build", function (_) {
            _.livescript("src/*.ls");
            _.livescript("src/packs/*.ls");
            _.sixToFive("src/*.js");
          });
        });
      });
    });
  });
});

transcript(tb);
