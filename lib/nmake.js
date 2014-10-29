(function(){
  var _, glob, path, fs, shelljs, minimatch, debug, hdebug, targets, phonyTargets, deps, cleanTargets, notifyTargets, watchSources, notifyStripString, notifyRewrites, silent, command, makefile, resetMakefile, addToMakefile, addDeps, error, Box, parse, watchSourceFiles, watchDestFiles, parseWatch, LIVERELOAD_PORT, lr, startLivereload, notifyChange, moment, color, os, table, name, description, author, year, info, err, warn, src, otm, cwd, setupTemporaryDirectory, removeTemporaryDirectory, usageString, optimist, argv, ref$, slice$ = [].slice, join$ = [].join;
  _ = require('underscore');
  _.str = require('underscore.string');
  glob = require('glob');
  _ = require('underscore');
  path = require('path');
  fs = require('fs');
  shelljs = require('shelljs');
  minimatch = require('minimatch');
  debug = require('debug')('normal');
  hdebug = require('debug')('highlight');
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
      this.copyTarget = bind$(this, 'copyTarget', prototype);
      this.collect = bind$(this, 'collect', prototype);
      this.processFiles = bind$(this, 'processFiles', prototype);
      this.reduceFiles = bind$(this, 'reduceFiles', prototype);
      this.compileFiles = bind$(this, 'compileFiles', prototype);
      this.addPlugin = bind$(this, 'addPlugin', prototype);
      this.toDir = bind$(this, 'toDir', prototype);
      this.notify = bind$(this, 'notify', prototype);
      this.dest = bind$(this, 'dest', prototype);
      this.getTmp = bind$(this, 'getTmp', prototype);
      this.createRootProductDest = bind$(this, 'createRootProductDest', prototype);
      this.createRootProductToDir = bind$(this, 'createRootProductToDir', prototype);
      this.createProcessedProduct = bind$(this, 'createProcessedProduct', prototype);
      this.createReductionProduct = bind$(this, 'createReductionProduct', prototype);
      this.createLeafProduct = bind$(this, 'createLeafProduct', prototype);
      this.fromName = bind$(this, 'fromName', prototype);
      this.prefixName = bind$(this, 'prefixName', prototype);
      this.changeFolder = bind$(this, 'changeFolder', prototype);
      this.changeExtension = bind$(this, 'changeExtension', prototype);
      this.finalize = bind$(this, 'finalize', prototype);
      this.getSourceDeps = bind$(this, 'getSourceDeps', prototype);
      this.understood = bind$(this, 'understood', prototype);
      this.notifyRewrite = bind$(this, 'notifyRewrite', prototype);
      this.notifyStrip = bind$(this, 'notifyStrip', prototype);
      this.unwrapObjects = bind$(this, 'unwrapObjects', prototype);
      this.prepareDir = bind$(this, 'prepareDir', prototype);
      this.genCleanRule = bind$(this, 'genCleanRule', prototype);
      this.removeAllTargets = bind$(this, 'removeAllTargets', prototype);
      this.onClean = bind$(this, 'onClean', prototype);
      this.make = bind$(this, 'make', prototype);
      this.cmd = bind$(this, 'cmd', prototype);
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
    prototype.cmd = function(comd){
      var name;
      name = "cmd-" + this.getTmp();
      this.createPhonyTarget(name, "", comd);
      return {
        buildTarget: name
      };
    };
    prototype.make = function(maketarget){
      var name;
      name = "cmd-" + this.getTmp();
      this.createPhonyTarget(name, "", "make maketarget");
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
    prototype.understood = function(finfo){
      var s;
      if (finfo.orig.ext == null) {
        console.log(new Error().stack);
        throw "Basename undefined";
      }
      s = "";
      if (finfo.orig) {
        s = s + ("\nfrom:  " + finfo.orig.baseDir + " / " + finfo.orig.baseName + " . " + finfo.orig.ext + " ( " + finfo.orig.completeName + " ) \n");
      }
      if (finfo.prod) {
        s = s + ("to:    " + finfo.prod.baseDir + " / " + finfo.prod.baseName + " . " + finfo.prod.ext + " ( " + finfo.prod.completeName + " ) \n");
      }
      return s;
    };
    prototype.getSourceDeps = function(array){
      var originalFiles, deps;
      originalFiles = this.unwrapObjects(array);
      deps = originalFiles.map(function(it){
        var ref$;
        if (((ref$ = it.prod) != null ? ref$.completeName : void 8) != null) {
          return it.prod.completeName;
        }
        if (it.buildTarget != null) {
          return it.buildTarget;
        }
        return "";
      });
      return join$.call(deps, ' ');
    };
    prototype.finalize = function(finfo){
      finfo.buildTarget = finfo.prod.completeName;
      finfo.origComplete = finfo.orig.completeName;
      return finfo;
    };
    prototype.changeExtension = curry$((function(newext, prevFinfo){
      var finfo;
      debug("change extension");
      debug(prevFinfo);
      finfo = {
        orig: prevFinfo.prod,
        prod: {}
      };
      finfo.prod.completeName = path.normalize(finfo.orig.baseDir + "/" + finfo.orig.baseName + newext);
      finfo.prod.ext = newext;
      finfo.prod.baseName = path.basename(finfo.prod.completeName, finfo.prod.ext);
      finfo.prod.baseDir = finfo.orig.baseDir;
      return this.finalize(finfo);
    }), true);
    prototype.changeFolder = curry$((function(folder, prevFinfo){
      var finfo;
      finfo = {
        orig: prevFinfo.prod,
        prod: {}
      };
      finfo.prod.completeName = path.normalize(folder + "/" + finfo.orig.baseName + finfo.orig.ext);
      finfo.prod.ext = finfo.orig.ext;
      finfo.prod.baseName = path.basename(finfo.prod.completeName, finfo.prod.ext);
      finfo.prod.baseDir = folder;
      return this.finalize(finfo);
    }), true);
    prototype.prefixName = curry$((function(prefix, prevFinfo){
      var finfo;
      finfo = {
        orig: prevFinfo.prod,
        prod: {}
      };
      finfo.prod.completeName = path.normalize(finfo.orig.baseDir + "/" + prefix + "-" + finfo.orig.baseName + finfo.orig.ext);
      finfo.prod.ext = finfo.orig.ext;
      finfo.prod.baseName = path.basename(finfo.prod.completeName, finfo.prod.ext);
      finfo.prod.baseDir = finfo.orig.baseDir;
      debug(this.understood(finfo));
      return this.finalize(finfo);
    }), true);
    prototype.fromName = function(name){
      var finfo;
      finfo = {
        orig: {},
        prod: {}
      };
      finfo.prod.completeName = path.normalize(name + "");
      finfo.prod.ext = path.extname(finfo.prod.completeName);
      finfo.prod.baseName = path.basename(finfo.prod.completeName, finfo.prod.ext);
      finfo.prod.baseDir = path.dirname(finfo.prod.completeName);
      return this.finalize(finfo);
    };
    prototype.createLeafProduct = function(originalFileName, newext){
      var finfo;
      finfo = {
        orig: this.fromName(originalFileName).prod
      };
      newext == null && (newext = finfo.orig.ext);
      finfo.prod = this.changeFolder(this.buildDir)(
      this.prefixName(this.getTmp())(
      this.changeExtension(newext)(
      this.fromName(originalFileName)))).prod;
      return this.finalize(finfo);
    };
    prototype.createReductionProduct = function(prodName){
      return this.fromName(this.buildDir + "/" + prodName);
    };
    prototype.createProcessedProduct = function(orig, newext, targetDir){
      var origProd, finalProd, finfo;
      origProd = orig.prod;
      finalProd = this.changeFolder(this.buildDir)(
      this.prefixName(this.getTmp())(
      this.changeExtension(newext)(
      orig))).prod;
      finfo = {
        orig: origProd,
        prod: finalProd
      };
      return this.finalize(finfo);
    };
    prototype.createRootProductToDir = function(dir, name, ext, orig){
      var finfo;
      finfo = {
        orig: orig
      };
      finfo.prod = this.fromName(dir + "/" + name + ext).prod;
      return this.finalize(finfo);
    };
    prototype.createRootProductDest = function(wholeName, orig){
      var finfo;
      finfo = {
        orig: orig
      };
      finfo.prod = this.fromName(wholeName).prod;
      return this.finalize(finfo);
    };
    prototype.getTmp = function(){
      this.tmp = this.tmp + 1;
      return this.tmp - 1;
    };
    prototype.dest = function(dname, body){
      var obj, o, dir, finfo;
      obj = this.unwrapObjects(body);
      if (obj.length > 1 || obj.length === 0) {
        throw "Sorry, `dest` can receive a single file only..";
      }
      o = obj[0];
      dir = this.prepareDir(dname);
      finfo = this.createRootProductDest(dname, o.prod);
      this.createTarget(dname, finfo.orig.completeName + " " + dir, "cp " + finfo.orig.completeName + " $@");
      return finfo;
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
      var obj, this$ = this;
      if (options.strip == null) {
        array = options;
        options = {};
      }
      debug(JSON.stringify(options));
      obj = this.unwrapObjects(array);
      hdebug("Unrapped");
      hdebug(obj);
      return obj.map(function(o){
        var baseDirStripped, dir, name, ext, finfo;
        debug("Considering destination " + dname);
        debug(o);
        if (!_.isEmpty(o.prod)) {
          baseDirStripped = o.orig.baseDir;
          if ((options != null ? options.strip : void 8) != null) {
            baseDirStripped = baseDirStripped.replace(options.strip, '');
          }
          dir = dname + "/" + baseDirStripped;
          name = o.orig.baseName;
          ext = o.prod.ext;
          finfo = this$.createRootProductToDir(dir, name, ext, o.prod);
          this$.createTarget(finfo.prod.completeName, o.prod.completeName + "", "@mkdir -p " + dir, "cp " + o.prod.completeName + " $@");
          return finfo;
        } else {
          throw "Skipping " + o.buildTarget + " 'cause no original dir can be found\n You might use `dest` for those files.";
        }
      });
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
    prototype.fileEscape = function(it){
      return it.replace(/'/, '\\\'');
    };
    prototype.compileFiles = function(action, ext, g, localDeps){
      var files, dfiles, this$ = this;
      files = glob.sync(g);
      if (localDeps != null) {
        localDeps = glob.sync(localDeps);
      } else {
        localDeps = [];
      }
      files = files.map(this.fileEscape);
      return dfiles = files.map(function(it){
        var dds, finfo;
        dds = localDeps.slice();
        finfo = this$.createLeafProduct(it, ext);
        if (!in$(it, dds)) {
          dds.push(it);
        }
        debug("Compiling files..");
        this$.createTarget(finfo.buildTarget + "", join$.call(dds, ' ') + "", action.bind(this$)(finfo));
        addDeps(dds);
        return finfo;
      });
    };
    prototype.reduceFiles = function(action, newName, ext, array){
      var finfo, deps;
      finfo = this.createReductionProduct(newName + "" + this.getTmp() + "." + ext);
      debug("Created reduction product");
      debug(finfo);
      deps = this.getSourceDeps(array);
      this.createTarget(finfo.buildTarget, deps, action);
      return finfo;
    };
    prototype.processFiles = function(action, ext, array){
      var files, dfiles, this$ = this;
      files = this.unwrapObjects(array);
      dfiles = files.map(function(it){
        var finfo;
        debug(it);
        finfo = this$.createProcessedProduct(it, ext);
        this$.createTarget(finfo.buildTarget, finfo.orig.completeName, action.bind(this$)(finfo));
        return finfo;
      });
      return dfiles;
    };
    prototype.commandSeq = function(body){
      var commands, names, name, comd, i;
      commands = this.unwrapObjects(body);
      names = commands.map(function(it){
        return it.buildTarget;
      });
      name = "cmd-seq-" + this.getTmp();
      comd = (function(){
        var i$, ref$, len$, results$ = [];
        for (i$ = 0, len$ = (ref$ = names).length; i$ < len$; ++i$) {
          i = ref$[i$];
          results$.push("make " + i);
        }
        return results$;
      }()).join('\n\t');
      this.createPhonyTarget(name, "", comd);
      return {
        buildTarget: name
      };
    };
    prototype.collect = function(name, options, array){
      var files, sourceBuildTargets, finfo;
      if (array == null) {
        array = options;
        options = {};
      }
      files = this.unwrapObjects(array);
      sourceBuildTargets = this.getSourceDeps(files);
      if (options.after != null) {
        if (_.isArray(options.after)) {
          sourceBuildTargets = sourceBuildTargets + (" " + join$.call(options.after, ' '));
        } else {
          sourceBuildTargets = sourceBuildTargets + (" " + options.after);
        }
      }
      this.createPhonyTarget(name, sourceBuildTargets);
      finfo = {
        orig: {},
        prod: {}
      };
      finfo.prod.completeName = name + "";
      finfo.prod.ext = "";
      finfo.prod.baseName = "";
      finfo.prod.baseDir = this.buildDir;
      finfo.buildTarget = finfo.prod.completeName;
      return finfo;
    };
    prototype.copyTarget = function(name){
      var finfo;
      finfo = {
        orig: {},
        prod: {}
      };
      finfo.prod.completeName = name;
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
  function curry$(f, bound){
    var context,
    _curry = function(args) {
      return f.length > 1 ? function(){
        var params = args ? args.concat() : [];
        context = bound ? context || this : this;
        return params.push.apply(params, arguments) <
            f.length && arguments.length ?
          _curry.call(context, params) : f.apply(context, params);
      } : f;
    };
    return _curry();
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
