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


targets = []
phony-targets = []
deps = []

makefile = ""

reset-makefile = ->
    makefile := ".DEFAULT_GOAL := all\n"

add-to-makefile = (line) ->
    makefile := makefile + "\n" + line

add-deps = (dep) ->
    if _.is-array(dep)
        deps := deps ++ [ path.resolve(d) for d in dep ]
    else 
        deps.push(path.resolve(dep))

error = (s) ->
    console.error "error: ",s





class Box 
    ->
        @tmp=0
        @dep-dirs=[]
        @build-dir = ".build"

    create-build-target: ~>
        @create-target-raw("#{@build-dir}", "", "mkdir -p #{@build-dir}")

    create-target: (name, deps, action) ->
        @create-build-target()
        @create-target-raw.apply(@, &)

    create-target-raw: (name, deps, action) ~>
        if not (name in targets)
            add-to-makefile "#name: #deps" 
            for d in &[2 to]
                add-to-makefile "\t#d"
            add-to-makefile ""
            targets.push(name)        

    create-phony-target: (name, deps, action) ->
        if not (name in phony-targets)
            add-to-makefile ".PHONY : #name"
            add-to-makefile "#name: #deps" 
            for d in &[2 to]
                add-to-makefile "\t#d"
            add-to-makefile ""
            phony-targets.push(name)

    cleanup-targets: ~>
        tgts = targets * ' '
        @create-target('clean', "", "rm -rf #{tgts}")

    prepare-dir: ~>
        dir = path.dirname(it)
        if dir != "" and dir != "."
            @create-target("#{dir}", "", "mkdir -p #{dir}")
        return dir

    unwrap-objects: (array) ~>
        if not _.is-array(array)
            array = [ array ]

        names = array.map ~> 
            if _.is-function(it)
                it.apply(@)
            else 
                it

        names = _.flatten(names)    

    get-build-targets: (array) ~>
        original-files = @unwrap-objects(array)
        source-build-targets = original-files.map (.build-target)
        return source-build-targets

    get-build-target-as-deps: (array) ~>
        source-build-targets = @get-build-targets(array) * ' '
        return source-build-targets

    create-leaf-product: (original-file-name, newext) ~>
        finfo               = {}
        finfo.orig-complete = original-file-name
        finfo.ext           = path.extname(original-file-name)
        finfo.orig-name     = path.basename(original-file-name, finfo.ext)
        finfo.orig-dir      = path.dirname(original-file-name)

        newext ?= finfo.ext
        finfo.dest-name    = "#{finfo.orig-name}#newext"
        finfo.build-target = "#{@build-dir}/#{finfo.dest-name}"
        return finfo

    create-reduction-product: (original-file-name) ~>
        finfo               = {}
        finfo.ext           = path.extname(original-file-name)
        finfo.orig-name     = path.basename(original-file-name, finfo.ext)
        finfo.orig-dir      = path.dirname(original-file-name)

        finfo.dest-name    = "#{finfo.orig-name}#{finfo.ext}"
        finfo.build-target = "#{@build-dir}/#{finfo.dest-name}"
        return finfo

    create-processed-product: (it, ext) ~>
            finfo              = {}
            finfo.orig-name    = it.orig-name
            finfo.orig-dir     = it.orig-dir
            finfo.dest-name    = "#{finfo.orig-name}#ext"
            finfo.build-target = "#{@build-dir}/#{finfo.dest-name}"
            return finfo

    get-tmp: ~>
        @tmp = @tmp + 1
        return @tmp - 1

    dest: (dname, body) ~>
        obj = @unwrap-objects(body)
        if obj.length > 1 or obj.length == 0
            throw "Sorry, `dest` can receive a single file only.."

        for o in obj 
            dest-dir = @prepare-dir(dname)
            @create-target(dname, "#{o.build-target} #dest-dir", "cp #{o.build-target} $@")

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

                @create-target("#dname/#{o.orig-dir}/#{o.dest-name}", 
                          "#{o.build-target}", 
                          "@mkdir -p #dname/#{o.orig-dir}", 
                          "cp #{o.build-target} #dname/#{o.orig-dir}")

                o.build-target = "#dname/#{o.orig-dir}/#{o.dest-name}"
            else
                console.error "Skipping #{o.build-target} 'cause no original dir can be found"
                console.error "You might use `dest` for those files."
        return obj


    #            _                        _ 
    #   _____  _| |_ ___ _ __ _ __   __ _| |
    #  / _ \ \/ / __/ _ \ '__| '_ \ / _` | |
    # |  __/>  <| ||  __/ |  | | | | (_| | |
    #  \___/_/\_\\__\___|_|  |_| |_|\__,_|_|


    compile-files: (action, ext, g, local-deps) ~>
        files = glob.sync(g)

        # if _.is-array(files) and local-deps?
        #     error files
        #     errorlocal-deps 
        #     throw "Sorry, you can't specify an array of files with dependencies"

        if local-deps? 
            local-deps := glob.sync(local-deps)
        else 
            local-deps := []

        dfiles = files.map ~>
            dds = local-deps.slice()
            finfo = @create-leaf-product(it, ext)
            if not (it in dds)
                dds.push(it)
            @create-target("#{finfo.build-target}", "#{dds * ' '} #{@build-dir}", action.bind(@)(finfo))
            add-deps(it)        
            return finfo                                          

    reduce-files: (action, new-name, ext, array) ~>
        finfo = @create-reduction-product("#new-name#{@get-tmp()}.#ext")
        deps = @get-build-target-as-deps(array)
        @create-target(finfo.build-target, deps, action)
        return finfo        

    process-files: (action, ext, array) ~>
        files = @unwrap-objects(array)
        dfiles = files.map ~>
            finfo = @create-processed-product(it, ext)
            @create-target(finfo.build-target, finfo.build-target, action.bind(@)(finfo))

    concat-ext: (ext, array) ~>
        @reduce-files("cat $^ > $@", "concat-tmp", ext, array)

    concatjs: ~>
        @concat-ext \js, it

    concatcss: ~>
        @concat-ext \css, it

    minifyjs: (array) ~>
        @process-files((-> "minifyjs -m -i #{it.build-target} > $@"), ".min.js", array)
        
    livescript: (g) ~>
        @compile-files( (-> "lsc -p -c #{it.orig-complete} > #{it.build-target}" ) , ".js", g)

    less: (g, deps) ~>
        @compile-files( (-> "lessc #{it.orig-complete} #{it.build-target}" ), ".css", g, deps )

    jade: (g, deps) ~>
        @compile-files( (-> "jade #{it.orig-complete} -o #{@build-dir}"), ".html", g, deps )

    glob: (g, deps) ~>
        @compile-files( (-> "cp #{it.orig-complete} #{it.build-target}"), undefined, g)

    copy: glob

    copy-target: (name) ~>
        finfo = {}
        finfo.build-target = "#name"
        return finfo

    collect: (name, array) ~>
        source-build-targets = @get-build-target-as-deps(array)
        @create-phony-target(name, source-build-targets)
        finfo = {}
        finfo.build-target = "#name"
        return finfo

parse = (b, cb) ->
    reset-makefile()
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
    {log, add-changed-file} = require('./screen')()

    log "Generating makefile"
    parse(b)
    shelljs.exec 'make all', {+silent}, ->
        log "First build completed"
        Gaze = require('gaze').Gaze;
        gaze = new Gaze('**/*.*');

        gaze.on 'ready', ->
            log "Watching.."

        gaze.on 'all', (event, filepath) ->
            
            log "Received #event for #filepath"
            if event == 'changed'
                if filepath in deps
                    # log "Changed file #filepath"
                    add-changed-file filepath
                    shelljs.exec 'make all', {+silent}, ->
                        log "Make done"
                else
                    log "Added/changed #filepath"
            else
                log "Added/changed file #filepath"
                parse b, -> 
                    shelljs.exec 'make all', {+silent}, ->
                        log "Make done"


module.exports = {
    parse: parse
    parse-watch: parse-watch
}




