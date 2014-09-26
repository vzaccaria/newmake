(function(){
  var _, glob, path, fs, shelljs, debug, log, targets, phonyTargets, deps, makefile, addToMakefile, addDeps, createTarget, createPhonyTarget, Box, parse, parseWatch, slice$ = [].slice, join$ = [].join;
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
  log = debug;
  targets = [];
  phonyTargets = [];
  deps = [];
  makefile = "";
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
  createTarget = function(name, deps, action){
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
  createPhonyTarget = function(name, deps, action){
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
  Box = (function(){
    Box.displayName = 'Box';
    var prototype = Box.prototype, constructor = Box;
    function Box(){
      this.collect = bind$(this, 'collect', prototype);
      this.glob = bind$(this, 'glob', prototype);
      this.less = bind$(this, 'less', prototype);
      this.livescript = bind$(this, 'livescript', prototype);
      this.unwrapObjects = bind$(this, 'unwrapObjects', prototype);
      this.minifyjs = bind$(this, 'minifyjs', prototype);
      this.concatcss = bind$(this, 'concatcss', prototype);
      this.concatjs = bind$(this, 'concatjs', prototype);
      this.concatExt = bind$(this, 'concatExt', prototype);
      this.toDir = bind$(this, 'toDir', prototype);
      this.dest = bind$(this, 'dest', prototype);
      this.getTmp = bind$(this, 'getTmp', prototype);
      this.createBuild = bind$(this, 'createBuild', prototype);
      this.prepareDir = bind$(this, 'prepareDir', prototype);
      this.cleanupTargets = bind$(this, 'cleanupTargets', prototype);
      this.tmp = 0;
      this.depDirs = [];
      this.buildDir = ".build";
    }
    prototype.cleanupTargets = function(){
      var tgts;
      tgts = join$.call(targets, ' ');
      return createTarget('clean', "", "rm -rf " + tgts);
    };
    prototype.prepareDir = function(it){
      var dir;
      dir = path.dirname(it);
      if (dir !== "" && dir !== ".") {
        createTarget(dir + "", "", "mkdir -p " + dir);
      }
      return dir;
    };
    prototype.createBuild = function(){
      createTarget(this.buildDir + "", "", "mkdir -p " + this.buildDir);
      return createPhonyTarget(this.buildDir + "-clean", "", "@rm -rf " + this.buildDir);
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
        createTarget(dname, o.buildTarget + " " + destDir, "cp " + o.buildTarget + " $@");
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
          createTarget(dname + "/" + o.origDir + "/" + o.destName, o.buildTarget + "", "@mkdir -p " + dname + "/" + o.origDir, "cp " + o.buildTarget + " " + dname + "/" + o.origDir);
          o.buildTarget = dname + "/" + o.origDir + "/" + o.destName;
        } else {
          console.error("Skipping " + o.buildTarget + " 'cause no original dir can be found");
          console.error("You might use `dest` for those files.");
        }
      }
      return obj;
    };
    prototype.concatExt = function(ext, array){
      var names, finfo, sourceBuildTargets, dname;
      names = this.unwrapObjects(array);
      finfo = {};
      finfo.origName = "concat-tmp" + this.getTmp();
      finfo.origDir = "(NONE)";
      finfo.destName = finfo.origName + "." + ext;
      finfo.buildTarget = this.buildDir + "/" + finfo.destName;
      sourceBuildTargets = names.map(function(it){
        return it.buildTarget;
      });
      names = join$.call(sourceBuildTargets, ' ');
      dname = finfo.buildTarget + "";
      this.createBuild();
      createTarget(dname, names, "cat $^ > $@");
      return finfo;
    };
    prototype.concatjs = function(it){
      return this.concatExt('js', it);
    };
    prototype.concatcss = function(it){
      return this.concatExt('css', it);
    };
    prototype.minifyjs = function(array){
      var names, dfiles, this$ = this;
      names = this.unwrapObjects(array);
      dfiles = names.map(function(it){
        var finfo;
        finfo = {};
        finfo.origName = it.origName;
        finfo.origDir = it.origDir;
        finfo.destName = finfo.origName + ".min.js";
        finfo.buildTarget = this$.buildDir + "/" + finfo.destName;
        this$.createBuild();
        createTarget(finfo.buildTarget, it.buildTarget, "minifyjs -m -i " + it.buildTarget + " > $@");
        return finfo;
      });
      return dfiles;
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
    prototype.livescript = function(g){
      var files, dfiles, this$ = this;
      files = glob.sync(g);
      dfiles = files.map(function(it){
        var finfo;
        finfo = {};
        finfo.ext = path.extname(it);
        finfo.origName = path.basename(it, finfo.ext);
        finfo.origDir = path.dirname(it);
        finfo.destName = finfo.origName + ".js";
        finfo.buildTarget = this$.buildDir + "/" + finfo.destName;
        this$.createBuild();
        createTarget(finfo.buildTarget + "", it + " " + this$.buildDir, "lsc -p -c " + it + " > " + finfo.buildTarget);
        addDeps(it);
        return finfo;
      });
      return dfiles;
    };
    prototype.less = function(files, deps){
      var dfiles, this$ = this;
      if (_.isArray(files) && deps != null) {
        throw "Sorry, you can't specify an array of files with dependencies";
      }
      files = glob.sync(files);
      if (deps != null) {
        deps = glob.sync(deps);
      } else {
        deps = [];
      }
      dfiles = files.map(function(it){
        var finfo;
        if (!in$(it, deps)) {
          deps.push(it);
        }
        finfo = {};
        finfo.ext = path.extname(it);
        finfo.origName = path.basename(it, finfo.ext);
        finfo.origDir = path.dirname(it);
        finfo.destName = finfo.origName + ".css";
        finfo.buildTarget = this$.buildDir + "/" + finfo.destName;
        this$.createBuild();
        createTarget(finfo.buildTarget + "", join$.call(deps, ' ') + " " + this$.buildDir, "lessc " + it + " " + finfo.buildTarget);
        addDeps(deps);
        return finfo;
      });
      return dfiles;
    };
    prototype.glob = function(files){
      var dfiles, this$ = this;
      files = glob.sync(files);
      dfiles = files.map(function(it){
        var finfo;
        finfo = {};
        finfo.ext = path.extname(it);
        finfo.origName = path.basename(it, finfo.ext);
        finfo.origDir = path.dirname(it);
        finfo.destName = finfo.origName + "" + finfo.ext;
        finfo.buildTarget = this$.buildDir + "/" + finfo.destName;
        this$.createBuild();
        createTarget(finfo.buildTarget + "", it + " " + this$.buildDir, "cp " + it + " " + finfo.buildTarget);
        addDeps(it);
        return finfo;
      });
      return dfiles;
    };
    prototype.collect = function(name, array){
      var names, sourceBuildTargets;
      names = this.unwrapObjects(array);
      sourceBuildTargets = join$.call(names.map(function(it){
        return it.buildTarget;
      }), ' ');
      return createPhonyTarget(name, sourceBuildTargets);
    };
    return Box;
  }());
  parse = function(b, cb){
    var bb;
    makefile = "";
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
    var Gaze, gaze;
    parse(b);
    Gaze = require('gaze').Gaze;
    gaze = new Gaze('**/*.*');
    gaze.on('ready', function(){
      return log("Watching..");
    });
    return gaze.on('all', function(event, filepath){
      log(event + " " + filepath);
      if (event === 'changed') {
        if (in$(filepath, deps)) {
          log("Changed file " + filepath);
          return shelljs.exec('make', function(){
            return log("done");
          });
        } else {
          return log("Other " + filepath);
        }
      } else {
        log("Added/removed file " + filepath);
        return parse(b, function(){
          return shelljs.exec('make', function(){
            return log("done");
          });
        });
      }
    });
  };
  module.exports = {
    parse: parse,
    parseWatch: parseWatch
  };
  function in$(x, xs){
    var i = -1, l = xs.length >>> 0;
    while (++i < l) if (x === xs[i]) return true;
    return false;
  }
  function bind$(obj, key, target){
    return function(){ return (target || obj)[key].apply(obj, arguments) };
  }
}).call(this);
