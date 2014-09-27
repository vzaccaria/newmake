(function(){
  var _, glob, path, fs, shelljs, debug, targets, phonyTargets, deps, makefile, resetMakefile, addToMakefile, addDeps, error, Box, parse, parseWatch, slice$ = [].slice, join$ = [].join;
  _ = require('underscore');
  _.str = require('underscore.string');
  glob = require('glob');
  _ = require('underscore');
  path = require('path');
  fs = require('fs');
  shelljs = require('shelljs');
  debug = require('debug')('nmake:core');
  _.mixin(_.str.exports());
  _.str.include('Underscore.string', 'string');
  targets = [];
  phonyTargets = [];
  deps = [];
  makefile = "";
  resetMakefile = function(){
    return makefile = ".DEFAULT_GOAL := all\n";
  };
  addToMakefile = function(line){
    return makefile = makefile + "\n" + line;
  };
  addDeps = function(dep){
    var d;
    if (_.isArray(dep)) {
      return deps = deps.concat((function(){
        var i$, ref$, len$, results$ = [];
        for (i$ = 0, len$ = (ref$ = dep).length; i$ < len$; ++i$) {
          d = ref$[i$];
          results$.push(path.resolve(d));
        }
        return results$;
      }()));
    } else {
      return deps.push(path.resolve(dep));
    }
  };
  error = function(s){
    return console.error("error: ", s);
  };
  Box = (function(){
    Box.displayName = 'Box';
    var prototype = Box.prototype, constructor = Box;
    function Box(){
      this.collect = bind$(this, 'collect', prototype);
      this.copyTarget = bind$(this, 'copyTarget', prototype);
      this.glob = bind$(this, 'glob', prototype);
      this.jade = bind$(this, 'jade', prototype);
      this.less = bind$(this, 'less', prototype);
      this.livescript = bind$(this, 'livescript', prototype);
      this.minifyjs = bind$(this, 'minifyjs', prototype);
      this.concatcss = bind$(this, 'concatcss', prototype);
      this.concatjs = bind$(this, 'concatjs', prototype);
      this.concatExt = bind$(this, 'concatExt', prototype);
      this.processFiles = bind$(this, 'processFiles', prototype);
      this.reduceFiles = bind$(this, 'reduceFiles', prototype);
      this.compileFiles = bind$(this, 'compileFiles', prototype);
      this.toDir = bind$(this, 'toDir', prototype);
      this.dest = bind$(this, 'dest', prototype);
      this.getTmp = bind$(this, 'getTmp', prototype);
      this.createProcessedProduct = bind$(this, 'createProcessedProduct', prototype);
      this.createReductionProduct = bind$(this, 'createReductionProduct', prototype);
      this.createLeafProduct = bind$(this, 'createLeafProduct', prototype);
      this.getBuildTargetAsDeps = bind$(this, 'getBuildTargetAsDeps', prototype);
      this.getBuildTargets = bind$(this, 'getBuildTargets', prototype);
      this.unwrapObjects = bind$(this, 'unwrapObjects', prototype);
      this.prepareDir = bind$(this, 'prepareDir', prototype);
      this.cleanupTargets = bind$(this, 'cleanupTargets', prototype);
      this.createTargetRaw = bind$(this, 'createTargetRaw', prototype);
      this.createBuildTarget = bind$(this, 'createBuildTarget', prototype);
      this.tmp = 0;
      this.depDirs = [];
      this.buildDir = ".build";
    }
    prototype.createBuildTarget = function(){
      return this.createTargetRaw(this.buildDir + "", "", "mkdir -p " + this.buildDir);
    };
    prototype.createTarget = function(name, deps, action){
      this.createBuildTarget();
      return this.createTargetRaw.apply(this, arguments);
    };
    prototype.createTargetRaw = function(name, deps, action){
      var i$, ref$, len$, d;
      if (!in$(name, targets)) {
        addToMakefile(name + ": " + deps);
        for (i$ = 0, len$ = (ref$ = slice$.call(arguments, 2)).length; i$ < len$; ++i$) {
          d = ref$[i$];
          addToMakefile("\t" + d);
        }
        addToMakefile("");
        return targets.push(name);
      }
    };
    prototype.createPhonyTarget = function(name, deps, action){
      var i$, ref$, len$, d;
      if (!in$(name, phonyTargets)) {
        addToMakefile(".PHONY : " + name);
        addToMakefile(name + ": " + deps);
        for (i$ = 0, len$ = (ref$ = slice$.call(arguments, 2)).length; i$ < len$; ++i$) {
          d = ref$[i$];
          addToMakefile("\t" + d);
        }
        addToMakefile("");
        return phonyTargets.push(name);
      }
    };
    prototype.cleanupTargets = function(){
      var tgts;
      tgts = join$.call(targets, ' ');
      return this.createTarget('clean', "", "rm -rf " + tgts);
    };
    prototype.prepareDir = function(it){
      var dir;
      dir = path.dirname(it);
      if (dir !== "" && dir !== ".") {
        this.createTarget(dir + "", "", "mkdir -p " + dir);
      }
      return dir;
    };
    prototype.unwrapObjects = function(array){
      var names, this$ = this;
      if (!_.isArray(array)) {
        array = [array];
      }
      names = array.map(function(it){
        if (_.isFunction(it)) {
          return it.apply(this$);
        } else {
          return it;
        }
      });
      return names = _.flatten(names);
    };
    prototype.getBuildTargets = function(array){
      var originalFiles, sourceBuildTargets;
      originalFiles = this.unwrapObjects(array);
      sourceBuildTargets = originalFiles.map(function(it){
        return it.buildTarget;
      });
      return sourceBuildTargets;
    };
    prototype.getBuildTargetAsDeps = function(array){
      var sourceBuildTargets;
      sourceBuildTargets = join$.call(this.getBuildTargets(array), ' ');
      return sourceBuildTargets;
    };
    prototype.createLeafProduct = function(originalFileName, newext){
      var finfo;
      finfo = {};
      finfo.origComplete = originalFileName;
      finfo.ext = path.extname(originalFileName);
      finfo.origName = path.basename(originalFileName, finfo.ext);
      finfo.origDir = path.dirname(originalFileName);
      newext == null && (newext = finfo.ext);
      finfo.destName = finfo.origName + "" + newext;
      finfo.buildTarget = this.buildDir + "/" + finfo.destName;
      return finfo;
    };
    prototype.createReductionProduct = function(originalFileName){
      var finfo;
      finfo = {};
      finfo.ext = path.extname(originalFileName);
      finfo.origName = path.basename(originalFileName, finfo.ext);
      finfo.origDir = path.dirname(originalFileName);
      finfo.destName = finfo.origName + "" + finfo.ext;
      finfo.buildTarget = this.buildDir + "/" + finfo.destName;
      return finfo;
    };
    prototype.createProcessedProduct = function(it, ext){
      var finfo;
      finfo = {};
      finfo.origName = it.origName;
      finfo.origDir = it.origDir;
      finfo.destName = finfo.origName + "" + ext;
      finfo.buildTarget = this.buildDir + "/" + finfo.destName;
      return finfo;
    };
    prototype.getTmp = function(){
      this.tmp = this.tmp + 1;
      return this.tmp - 1;
    };
    prototype.dest = function(dname, body){
      var obj, i$, len$, o, destDir;
      obj = this.unwrapObjects(body);
      if (obj.length > 1 || obj.length === 0) {
        throw "Sorry, `dest` can receive a single file only..";
      }
      for (i$ = 0, len$ = obj.length; i$ < len$; ++i$) {
        o = obj[i$];
        destDir = this.prepareDir(dname);
        this.createTarget(dname, o.buildTarget + " " + destDir, "cp " + o.buildTarget + " $@");
      }
      obj[0].buildTarget = dname;
      return obj;
    };
    prototype.toDir = function(dname, options, array){
      var obj, i$, len$, o;
      if (options.strip == null) {
        array = options;
        options = {};
      }
      debug(JSON.stringify(options));
      obj = this.unwrapObjects(array);
      for (i$ = 0, len$ = obj.length; i$ < len$; ++i$) {
        o = obj[i$];
        if (o.origDir !== "(NONE)") {
          if ((options != null ? options.strip : void 8) != null) {
            debug("Stripping " + o.origDir);
            o.origDir = o.origDir.replace(options.strip, '');
          }
          this.createTarget(dname + "/" + o.origDir + "/" + o.destName, o.buildTarget + "", "@mkdir -p " + dname + "/" + o.origDir, "cp " + o.buildTarget + " " + dname + "/" + o.origDir);
          o.buildTarget = dname + "/" + o.origDir + "/" + o.destName;
        } else {
          console.error("Skipping " + o.buildTarget + " 'cause no original dir can be found");
          console.error("You might use `dest` for those files.");
        }
      }
      return obj;
    };
    prototype.compileFiles = function(action, ext, g, localDeps){
      var files, dfiles, this$ = this;
      files = glob.sync(g);
      if (localDeps != null) {
        localDeps = glob.sync(localDeps);
      } else {
        localDeps = [];
      }
      return dfiles = files.map(function(it){
        var dds, finfo;
        dds = localDeps.slice();
        finfo = this$.createLeafProduct(it, ext);
        if (!in$(it, dds)) {
          dds.push(it);
        }
        this$.createTarget(finfo.buildTarget + "", join$.call(dds, ' ') + " " + this$.buildDir, action.bind(this$)(finfo));
        addDeps(it);
        return finfo;
      });
    };
    prototype.reduceFiles = function(action, newName, ext, array){
      var finfo, deps;
      finfo = this.createReductionProduct(newName + "" + this.getTmp() + "." + ext);
      deps = this.getBuildTargetAsDeps(array);
      this.createTarget(finfo.buildTarget, deps, action);
      return finfo;
    };
    prototype.processFiles = function(action, ext, array){
      var files, dfiles, this$ = this;
      files = this.unwrapObjects(array);
      return dfiles = files.map(function(it){
        var finfo;
        finfo = this$.createProcessedProduct(it, ext);
        return this$.createTarget(finfo.buildTarget, finfo.buildTarget, action.bind(this$)(finfo));
      });
    };
    prototype.concatExt = function(ext, array){
      return this.reduceFiles("cat $^ > $@", "concat-tmp", ext, array);
    };
    prototype.concatjs = function(it){
      return this.concatExt('js', it);
    };
    prototype.concatcss = function(it){
      return this.concatExt('css', it);
    };
    prototype.minifyjs = function(array){
      return this.processFiles(function(it){
        return "minifyjs -m -i " + it.buildTarget + " > $@";
      }, ".min.js", array);
    };
    prototype.livescript = function(g){
      return this.compileFiles(function(it){
        return "lsc -p -c " + it.origComplete + " > " + it.buildTarget;
      }, ".js", g);
    };
    prototype.less = function(g, deps){
      return this.compileFiles(function(it){
        return "lessc " + it.origComplete + " " + it.buildTarget;
      }, ".css", g, deps);
    };
    prototype.jade = function(g, deps){
      return this.compileFiles(function(it){
        return "jade " + it.origComplete + " -o " + this.buildDir;
      }, ".html", g, deps);
    };
    prototype.glob = function(g, deps){
      return this.compileFiles(function(it){
        return "cp " + it.origComplete + " " + it.buildTarget;
      }, undefined, g);
    };
    prototype.copy = glob;
    prototype.copyTarget = function(name){
      var finfo;
      finfo = {};
      finfo.buildTarget = name + "";
      return finfo;
    };
    prototype.collect = function(name, array){
      var sourceBuildTargets, finfo;
      sourceBuildTargets = this.getBuildTargetAsDeps(array);
      this.createPhonyTarget(name, sourceBuildTargets);
      finfo = {};
      finfo.buildTarget = name + "";
      return finfo;
    };
    return Box;
  }());
  parse = function(b, cb){
    var bb;
    resetMakefile();
    deps = [];
    targets = [];
    phonyTargets = [];
    bb = new Box;
    b.apply(bb);
    if (cb == null) {
      return fs.writeFileSync('makefile', makefile);
    } else {
      return fs.writeFile('makefile', makefile, cb);
    }
  };
  parseWatch = function(b){
    var ref$, log, addChangedFile;
    ref$ = require('./screen')(), log = ref$.log, addChangedFile = ref$.addChangedFile;
    log("Generating makefile");
    parse(b);
    return shelljs.exec('make all', {
      silent: true
    }, function(){
      var Gaze, gaze;
      log("First build completed");
      Gaze = require('gaze').Gaze;
      gaze = new Gaze('**/*.*');
      gaze.on('ready', function(){
        return log("Watching..");
      });
      return gaze.on('all', function(event, filepath){
        log("Received " + event + " for " + filepath);
        if (event === 'changed') {
          if (in$(filepath, deps)) {
            addChangedFile(filepath);
            return shelljs.exec('make all', {
              silent: true
            }, function(){
              return log("Make done");
            });
          } else {
            return log("Added/changed " + filepath);
          }
        } else {
          log("Added/changed file " + filepath);
          return parse(b, function(){
            return shelljs.exec('make all', {
              silent: true
            }, function(){
              return log("Make done");
            });
          });
        }
      });
    });
  };
  module.exports = {
    parse: parse,
    parseWatch: parseWatch
  };
  function bind$(obj, key, target){
    return function(){ return (target || obj)[key].apply(obj, arguments) };
  }
  function in$(x, xs){
    var i = -1, l = xs.length >>> 0;
    while (++i < l) if (x === xs[i]) return true;
    return false;
  }
}).call(this);
