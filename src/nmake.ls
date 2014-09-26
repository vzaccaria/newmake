#!/usr/bin/env lsc

_       = require('underscore')
_.str   = require('underscore.string');
glob    = require 'glob'
_       = require 'underscore'
path    = require 'path'
fs      = require 'fs'
shelljs = require 'shelljs'

debug = require('debug')('nmake:core')

_.mixin(_.str.exports());
_.str.include('Underscore.string', 'string');

log = debug

targets = []
phony-targets = []
deps = []

makefile = ""

add-to-makefile = (line) ->
    makefile := makefile + "\n" + line

add-deps = (dep) ->
    if _.is-array(dep)
        deps := deps ++ [ path.resolve(d) for d in dep ]
    else 
        deps.push(path.resolve(dep))


create-target = (name, deps, action) ->
    if not (name in targets)
        add-to-makefile "#name: #deps" 
        for d in &[2 to]
            add-to-makefile "\t#d"
        add-to-makefile ""
        targets.push(name)

create-phony-target = (name, deps, action) ->
    if not (name in phony-targets)
        add-to-makefile ".PHONY : #name"
        add-to-makefile "#name: #deps" 
        for d in &[2 to]
            add-to-makefile "\t#d"
        add-to-makefile ""
        phony-targets.push(name)


class Box 
    ->
        @tmp=0
        @dep-dirs=[]
        @build-dir = ".build"

    cleanup-targets: ~>
        tgts = targets * ' '
        create-target('clean', "", "rm -rf #{tgts}")

    prepare-dir: ~>
        dir = path.dirname(it)
        if dir != "" and dir != "."
            create-target("#{dir}", "", "mkdir -p #{dir}")
        return dir

    create-build: ~>
        create-target("#{@build-dir}", "", "mkdir -p #{@build-dir}")

    get-tmp: ~>
        @tmp = @tmp + 1
        return @tmp - 1

    dest: (dname, body) ~>
        obj = @unwrap-objects(body)
        if obj.length > 1 or obj.length == 0
            throw "Sorry, `dest` can receive a single file only.."

        for o in obj 
            dest-dir = @prepare-dir(dname)
            create-target(dname, "#{o.build-target} #dest-dir", "cp #{o.build-target} $@")

        obj[0].build-target = dname
        return obj


    to-dir: (dname, options, array) ~>
        if not options.strip? 
            array = options 
            options = {}

        debug JSON.stringify(options)

        obj = @unwrap-objects(array)
        for o in obj
            if o.orig-dir != "(NONE)"
                if options?.strip?
                    debug "Stripping #{o.orig-dir}"
                    o.orig-dir = o.orig-dir.replace(options.strip, '')

                create-target("#dname/#{o.orig-dir}/#{o.dest-name}", 
                          "#{o.build-target}", 
                          "@mkdir -p #dname/#{o.orig-dir}", 
                          "cp #{o.build-target} #dname/#{o.orig-dir}")

                o.build-target = "#dname/#{o.orig-dir}/#{o.dest-name}"
            else
                console.error "Skipping #{o.build-target} 'cause no original dir can be found"
                console.error "You might use `dest` for those files."
        return obj

    concat-ext: (ext, array) ~>
        names = @unwrap-objects(array)

        finfo = {}
        finfo.orig-name    = "concat-tmp#{@get-tmp()}" 
        finfo.orig-dir     = "(NONE)"
        finfo.dest-name    = "#{finfo.orig-name}.#ext"
        finfo.build-target = "#{@build-dir}/#{finfo.dest-name}"

        source-build-targets = names.map (.build-target)

        names = source-build-targets * ' '
        dname = "#{finfo.build-target}"
        @create-build()
        create-target(dname, names, "cat $^ > $@")
        return finfo

    concatjs: ~>
        @concat-ext \js, it

    concatcss: ~>
        @concat-ext \css, it

    minifyjs: (array) ~>
        names = @unwrap-objects(array)

        dfiles = names.map ~>
            finfo              = {}
            finfo.orig-name    = it.orig-name
            finfo.orig-dir     = it.orig-dir
            finfo.dest-name    = "#{finfo.orig-name}.min.js"
            finfo.build-target = "#{@build-dir}/#{finfo.dest-name}"
            @create-build()
            create-target(finfo.build-target, it.build-target, "minifyjs -m -i #{it.build-target} > $@")
            return finfo

        return dfiles

    unwrap-objects: (array) ~>
        if not _.is-array(array)
            array = [ array ]

        names = array.map ~> 
            if _.is-function(it)
                it.apply(@)
            else 
                it

        names = _.flatten(names)            


    livescript: (g) ~>
        files = glob.sync(g)
        dfiles = files.map ~>

            finfo              = {}
            finfo.ext          = path.extname(it)
            finfo.orig-name    = path.basename(it, finfo.ext)
            finfo.orig-dir     = path.dirname(it)
            finfo.dest-name    = "#{finfo.orig-name}.js"
            finfo.build-target = "#{@build-dir}/#{finfo.dest-name}"

            @create-build()
            create-target("#{finfo.build-target}", "#it #{@build-dir}", "lsc -p -c #it > #{finfo.build-target}")
            add-deps(it)
            return finfo
        return dfiles

    less: (files, deps) ~>
        if _.is-array(files) and deps?
            throw "Sorry, you can't specify an array of files with dependencies"
        files = glob.sync(files)
        if deps? 
            deps = glob.sync(deps)
        else 
            deps = []

        dfiles = files.map ~>
            if not (it in deps)
                deps.push(it)
            finfo              = {}
            finfo.ext          = path.extname(it)
            finfo.orig-name    = path.basename(it, finfo.ext)
            finfo.orig-dir     = path.dirname(it)
            finfo.dest-name    = "#{finfo.orig-name}.css"
            finfo.build-target = "#{@build-dir}/#{finfo.dest-name}"
            @create-build()
            create-target("#{finfo.build-target}", "#{deps * ' '} #{@build-dir}", "lessc #it #{finfo.build-target}")
            add-deps(deps)
            return finfo
        return dfiles

    glob: (files) ~>
        files = glob.sync(files)
        dfiles = files.map ~>

            finfo              = {}
            finfo.ext          = path.extname(it)
            finfo.orig-name    = path.basename(it, finfo.ext)
            finfo.orig-dir     = path.dirname(it)
            finfo.dest-name    = "#{finfo.orig-name}#{finfo.ext}"
            finfo.build-target = "#{@build-dir}/#{finfo.dest-name}"

            @create-build()
            create-target("#{finfo.build-target}", "#it #{@build-dir}", "cp #it #{finfo.build-target}")
            add-deps(it)
            return finfo
        return dfiles



    collect: (name, array) ~>
        names = @unwrap-objects(array)
        source-build-targets = (names.map (.build-target)) * ' '
        create-phony-target(name, source-build-targets)
        finfo = {}
        finfo.build-target = "#name"
        return finfo




parse = (b, cb) ->
    makefile := ""
    deps := []
    targets := []
    phony-targets := []
    bb = new Box
    b.apply(bb)
    if not cb?
        fs.writeFileSync('makefile', makefile)
    else
        fs.writeFile('makefile', makefile, cb)

parse-watch = (b) ->
    parse(b)
    Gaze = require('gaze').Gaze;
    gaze = new Gaze('**/*.*');

    gaze.on 'ready', ->
        log "Watching.."

    gaze.on 'all', (event, filepath) ->
        log "#event #filepath"
        if event == 'changed'
            if filepath in deps
                log "Changed file #filepath"
                shelljs.exec 'make all', ->
                    log "done"
            else
                log "Other #filepath"
        else
            log "Added/removed file #filepath"
            parse b, -> 
                shelljs.exec 'make all', ->
                    log "done"


module.exports = {
    parse: parse
    parse-watch: parse-watch
}




