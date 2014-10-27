(function(){
  var plugins;
  plugins = {
    concatExt: function(ext, array){
      return this.reduceFiles("cat $^ > $@", "concat-tmp", ext, array);
    },
    concatjs: function(it){
      return this.concatExt('js', it);
    },
    concatcss: function(it){
      return this.concatExt('css', it);
    },
    compressjs: function(array){
      return this.processFiles(function(it){
        return "gzip < " + it.buildTarget + " > $@";
      }, ".js.gz", array);
    },
    compresscss: function(array){
      return this.processFiles(function(it){
        return "gzip < " + it.buildTarget + " > $@";
      }, ".css.gz", array);
    },
    minifyjs: function(array){
      return this.processFiles(function(it){
        return "uglifyjs " + it.origComplete + " -c -m  > $@";
      }, ".min.js", array);
    },
    livescript: function(g){
      return this.compileFiles(function(it){
        return "lsc -p -c " + it.origComplete + " > " + it.buildTarget;
      }, ".js", g);
    },
    less: function(g, deps){
      return this.compileFiles(function(it){
        return "lessc " + it.origComplete + " " + it.buildTarget;
      }, ".css", g, deps);
    },
    jade: function(g, deps){
      return this.compileFiles(function(it){
        return "jade -p " + it.origComplete + " < " + it.origComplete + " > " + it.buildTarget;
      }, ".html", g, deps);
    },
    browserify: function(g, deps){
      return this.compileFiles(function(it){
        return "browserify -t liveify " + it.origComplete + " -o " + it.buildTarget;
      }, ".js", g, deps);
    },
    exec: function(cmd, ext, g, deps){
      return this.compileFiles(cmd, ext, g, deps);
    },
    glob: function(g, deps){
      return this.compileFiles(function(it){
        return "cp " + it.origComplete + " " + it.buildTarget;
      }, undefined, g);
    },
    copy: function(g, deps){
      return this.glob(g, deps);
    }
  };
  module.exports = function(){
    var n, ref$, p, results$ = [];
    for (n in ref$ = plugins) {
      p = ref$[n];
      results$.push(this.addPlugin(n, p));
    }
    return results$;
  };
}).call(this);
