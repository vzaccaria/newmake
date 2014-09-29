
plugins = 

    concat-ext: (ext, array) ->
        @reduce-files("cat $^ > $@", "concat-tmp", ext, array)

    concatjs: ->
        @concat-ext \js, it

    concatcss: ->
        @concat-ext \css, it

    minifyjs: (array) ->
        @process-files((-> "minifyjs -m -i #{it.build-target} > $@"), ".min.js", array)
        
    livescript: (g) ->
        @compile-files( (-> "lsc -p -c #{it.orig-complete} > #{it.build-target}" ) , ".js", g)

    less: (g, deps) ->
        @compile-files( (-> "lessc #{it.orig-complete} #{it.build-target}" ), ".css", g, deps )

    jade: (g, deps) ->
        @compile-files( (-> "jade -p #{it.orig-complete} < #{it.orig-complete} > #{it.build-target}"), ".html", g, deps )

    browserify: (g, deps) ->
        @compile-files( (-> "browserify -t liveify #{it.orig-complete} -o #{it.build-target}"), ".js", g, deps)

    exec: (cmd, ext, g, deps) ->
        @compile-files(cmd, ext, g, deps)

    glob: (g, deps) ->
        @compile-files( (-> "cp #{it.orig-complete} #{it.build-target}"), undefined, g)

    copy: (g, deps)  ->
        @glob(g, deps)

module.exports = ->
    for n, p of plugins
        @add-plugin n, p

