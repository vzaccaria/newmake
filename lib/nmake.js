(function(){
  var _, glob, path, fs, shelljs, minimatch, debug, targets, phonyTargets, deps, cleanTargets, notifyTargets, watchSources, notifyStripString, notifyRewrites, silent, command, makefile, resetMakefile, addToMakefile, addDeps, error, Box, parse, watchSourceFiles, watchDestFiles, parseWatch, LIVERELOAD_PORT, lr, startLivereload, notifyChange, moment, color, os, table, name, description, author, year, info, err, warn, src, otm, cwd, setupTemporaryDirectory, removeTemporaryDirectory, usageString, optimist, argv, ref$, slice$ = [].slice, join$ = [].join;
  _ = require('underscore');
  _.str = require('underscore.string');
  glob = require('glob');
  _ = require('underscore');
  path = require('path');
  fs = require('fs');
  shelljs = require('shelljs');
  minimatch = require('minimatch');
  debug = require('debug')('nmake:core');
  _.mixin(_.str.exports());
  _.str.include('Underscore.string', 'string');
  targets = [];
  phonyTargets = [];
  deps = [];
  cleanTargets = [];
  notifyTargets = [];
  watchSources = [];
  notifyStripString = "";
  notifyRewrites = [];
  silent = false;
  command = "";
  makefile = "";
  resetMakefile = function(){
    makefile = ".DEFAULT_GOAL := all\n";
    deps = [];
    targets = [];
    phonyTargets = [];
    cleanTargets = [];
    notifyTargets = [];
    watchSources = [];
    return notifyStripString = "";
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
      this.processFiles = bind$(this, 'processFiles', prototype);
      this.reduceFiles = bind$(this, 'reduceFiles', prototype);
      this.compileFiles = bind$(this, 'compileFiles', prototype);
      this.addPlugin = bind$(this, 'addPlugin', prototype);
      this.toDir = bind$(this, 'toDir', prototype);
      this.notify = bind$(this, 'notify', prototype);
      this.dest = bind$(this, 'dest', prototype);
      this.getTmp = bind$(this, 'getTmp', prototype);
      this.createProcessedProduct = bind$(this, 'createProcessedProduct', prototype);
      this.createReductionProduct = bind$(this, 'createReductionProduct', prototype);
      this.createLeafProduct = bind$(this, 'createLeafProduct', prototype);
      this.getBuildTargetAsDeps = bind$(this, 'getBuildTargetAsDeps', prototype);
      this.getBuildTargets = bind$(this, 'getBuildTargets', prototype);
      this.notifyRewrite = bind$(this, 'notifyRewrite', prototype);
      this.notifyStrip = bind$(this, 'notifyStrip', prototype);
      this.unwrapObjects = bind$(this, 'unwrapObjects', prototype);
      this.prepareDir = bind$(this, 'prepareDir', prototype);
      this.genCleanRule = bind$(this, 'genCleanRule', prototype);
      this.removeAllTargets = bind$(this, 'removeAllTargets', prototype);
      this.onClean = bind$(this, 'onClean', prototype);
      this.cmdExec = bind$(this, 'cmdExec', prototype);
      this.createTargetRaw = bind$(this, 'createTargetRaw', prototype);
      this.tmp = 0;
      this.depDirs = [];
      this.buildDir = ".build";
    }
    prototype.createTarget = function(name, deps, action){
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
    prototype.cmdExec = function(name, cmd){
      name = name + "-" + this.getTmp();
      this.createPhonyTarget(name, "", cmd);
      return {
        buildTarget: name
      };
    };
    prototype.onClean = function(cmd){
      var name;
      name = "clean-" + this.getTmp();
      this.createPhonyTarget(name, "", cmd);
      cleanTargets.push(name);
      return {
        buildTarget: name
      };
    };
    prototype.removeAllTargets = function(){
      var tgts;
      tgts = join$.call(targets, ' ');
      return [this.onClean("rm -rf " + tgts), this.onClean("rm -rf " + this.buildDir), this.onClean("mkdir -p " + this.buildDir)];
    };
    prototype.genCleanRule = function(){
      return this.createPhonyTarget('clean', join$.call(cleanTargets, ' '));
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
    prototype.notifyStrip = function(s){
      return notifyStripString = s;
    };
    prototype.notifyRewrite = function(target, glob){
      return notifyRewrites.push({
        target: target,
        glob: glob
      });
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
      finfo.buildTarget = this.buildDir + "/" + this.getTmp() + "-" + finfo.destName;
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
    prototype.notify = function(body){
      var obj, i$, len$, o;
      obj = this.unwrapObjects(body);
      for (i$ = 0, len$ = obj.length; i$ < len$; ++i$) {
        o = obj[i$];
        notifyTargets.push(o.buildTarget);
      }
      return obj;
    };
    prototype.toDir = function(dname, options, array){
      var obj, i$, len$, o, bt;
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
          bt = path.normalize(dname + "/" + o.origDir + "/" + o.destName);
          this.createTarget(bt, o.buildTarget + "", "@mkdir -p " + dname + "/" + o.origDir, "cp " + o.buildTarget + " $@");
          o.buildTarget = bt;
        } else {
          console.error("Skipping " + o.buildTarget + " 'cause no original dir can be found");
          console.error("You might use `dest` for those files.");
        }
      }
      return obj;
    };
    prototype.foreverWatch = function(dname, opts){
      var cmd, runTarget;
      if ((opts != null ? opts.root : void 8) == null) {
        throw "Please specify a root for forever to work";
      }
      cmd = "forever -w --watchDirectory " + dname + " " + opts.root;
      if ((opts != null ? opts.ignore : void 8) != null) {
        cmd = cmd + " --watchIgnore " + opts.ignore;
      }
      runTarget = "run-" + this.getTmp();
      this.createPhonyTarget(runTarget, "", cmd);
      return {
        buildTarget: runTarget
      };
    };
    prototype.addPlugin = function(name, action){
      return this[name] = action.bind(this);
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
        this$.createTarget(finfo.buildTarget + "", join$.call(dds, ' ') + "", action.bind(this$)(finfo));
        addDeps(dds);
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
    debug("Generating makefile");
    resetMakefile();
    bb = new Box;
    require('./plugin').apply(bb);
    b.apply(bb);
    if (cb == null) {
      fs.writeFileSync('makefile', makefile);
    } else {
      fs.writeFile('makefile', makefile, cb);
    }
    if (command !== "") {
      shelljs.exec("make " + command + " -j", {
        silent: silent
      }, function(){
        return debug("Make done");
      });
    }
    return watchSources = deps;
  };
  watchSourceFiles = function(cb){
    var Gaze, gaze, this$ = this;
    debug("First build completed");
    Gaze = require('gaze').Gaze;
    watchSources = watchSources.map(function(it){
      return path.resolve(it);
    });
    gaze = new Gaze(watchSources);
    gaze.on('ready', function(){
      return debug("Watching sources. " + watchSources.length);
    });
    return gaze.on('all', cb);
  };
  watchDestFiles = function(cb){
    var Gaze, gaze, this$ = this;
    debug("First build completed");
    Gaze = require('gaze').Gaze;
    notifyTargets = notifyTargets.map(function(it){
      return path.resolve(it);
    });
    gaze = new Gaze(notifyTargets);
    gaze.on('ready', function(){
      return debug("Watching destinations. " + notifyTargets.length);
    });
    return gaze.on('all', cb);
  };
  parseWatch = function(b){
    var this$ = this;
    parse(b);
    notifyTargets = notifyTargets.map(function(it){
      return path.resolve(it);
    });
    startLivereload();
    if (command === "") {
      command = 'all';
    }
    return shelljs.exec('make all -j', {
      silent: silent
    }, function(){
      watchSourceFiles(function(event, filepath){
        debug("Received " + event + " for " + filepath);
        if (event === 'changed') {
          return shelljs.exec("make " + command + " -j", function(){});
        } else {
          debug("Added/changed file " + filepath);
          return parse(b, function(){
            return shelljs.exec('make #command -j', {
              silent: true
            }, function(){
              return debug("Make done");
            });
          });
        }
      });
      return watchDestFiles(function(event, filepath){
        return notifyChange(filepath);
      });
    });
  };
  LIVERELOAD_PORT = 35729;
  startLivereload = function(){
    lr = require('tiny-lr')();
    debug(lr);
    return lr.listen(LIVERELOAD_PORT);
  };
  notifyChange = function(path){
    var fileName, found, delay, i$, ref$, len$, w;
    fileName = require('path').relative(notifyStripString, path);
    found = false;
    delay = partialize$.apply(this, [setTimeout, [void 8, 100], [0]]);
    for (i$ = 0, len$ = (ref$ = notifyRewrites).length; i$ < len$; ++i$) {
      w = ref$[i$];
      (fn$.call(this, w, w));
    }
    if (!found) {
      return delay(function(){
        return lr.changed({
          body: {
            files: [fileName]
          }
        });
      });
    }
    function fn$(x, w){
      debug("checking for " + fileName + ", " + x.glob);
      if (minimatch(fileName, x.glob)) {
        debug("Notifying Livereload for a change to " + x.target);
        delay(function(){
          return lr.changed({
            body: {
              files: [x.target]
            }
          });
        });
        found = true;
      }
    }
  };
  _ = require('underscore');
  _.str = require('underscore.string');
  moment = require('moment');
  fs = require('fs');
  color = require('ansi-color').set;
  os = require('os');
  shelljs = require('shelljs');
  table = require('ansi-color-table');
  _.mixin(_.str.exports());
  _.str.include('Underscore.string', 'string');
  name = "newmake";
  description = "A tiny make helper";
  author = "Vittorio Zaccaria";
  year = "2014";
  info = function(s){
    return console.log(color('inf', 'bold') + (": " + s));
  };
  err = function(s){
    return console.log(color('err', 'red') + (": " + s));
  };
  warn = function(s){
    return console.log(color('wrn', 'yellow') + (": " + s));
  };
  src = __dirname;
  otm = os.tmpdir != null ? os.tmpdir() : "/var/tmp";
  cwd = process.cwd();
  setupTemporaryDirectory = function(){
    var name, dire;
    name = "tmp_" + moment().format('HHmmss') + "_tmp";
    dire = otm + "/" + name;
    shelljs.mkdir('-p', dire);
    return dire;
  };
  removeTemporaryDirectory = function(dir){
    return shelljs.rm('-rf', dir);
  };
  usageString = "\n" + color(name, 'bold') + ". " + description + "\n(c) " + author + ", " + year + "\n\nUsage: " + name + " [--option=V | -o V] ";
  optimist = require('optimist');
  argv = optimist.usage(usageString, {
    watch: {
      alias: 'w',
      description: 'watch and rebuild',
      boolean: true,
      'default': false
    },
    silent: {
      alias: 's',
      description: 'silent mode',
      boolean: true,
      'default': false
    },
    help: {
      alias: 'h',
      description: 'this help',
      'default': false
    }
  }).boolean('h').argv;
  if (argv.help) {
    optimist.showHelp();
    process.exit(0);
    return;
  }
  if (((ref$ = argv._) != null ? ref$[0] : void 8) != null) {
    command = argv._[0];
  }
  silent = argv.silent;
  if (argv.watch) {
    module.exports = {
      parse: parseWatch
    };
  } else {
    module.exports = {
      parse: parse
    };
  }
  function bind$(obj, key, target){
    return function(){ return (target || obj)[key].apply(obj, arguments) };
  }
  function in$(x, xs){
    var i = -1, l = xs.length >>> 0;
    while (++i < l) if (x === xs[i]) return true;
    return false;
  }
  function partialize$(f, args, where){
    var context = this;
    return function(){
      var params = slice$.call(arguments), i,
          len = params.length, wlen = where.length,
          ta = args ? args.concat() : [], tw = where ? where.concat() : [];
      for(i = 0; i < len; ++i) { ta[tw[0]] = params[i]; tw.shift(); }
      return len < wlen && len ?
        partialize$.apply(context, [f, ta, tw]) : f.apply(context, ta);
    };
  }
}).call(this);
