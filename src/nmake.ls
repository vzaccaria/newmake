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


targets             = []
phony-targets       = []
deps                = []
clean-targets       = []
notify-targets      = []
watch-sources       = []
notify-strip-string = ""
silent              = false
command             = ""
makefile            = ""

reset-makefile = ->
    makefile := ".DEFAULT_GOAL := all\n"
    deps := []
    targets := []
    phony-targets := []
    clean-targets := []
    notify-targets := []
    watch-sources := []
    notify-strip-string := ""

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

    create-target: (name, deps, action) ->
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

    cmd-exec: (name, cmd) ~>
        name = "#name-#{@get-tmp()}"
        @create-phony-target(name, "", cmd)
        return { build-target: name }

    on-clean: (cmd) ~>
        name = "clean-#{@get-tmp()}"
        @create-phony-target(name, "", cmd)
        clean-targets.push(name)
        return { build-target: name }

    remove-all-targets: ~>
        tgts = targets * ' '
        return [
            @on-clean "rm -rf #{tgts}"
            @on-clean "rm -rf #{@build-dir}"
            @on-clean "mkdir -p #{@build-dir}"
        ]

    gen-clean-rule: ~>
        @create-phony-target('clean', (clean-targets * ' '))

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

    notify-strip: (s) ~>
        notify-strip-string := s

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
        finfo.build-target = "#{@build-dir}/#{@get-tmp()}-#{finfo.dest-name}"
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

    notify: (body) ~>
        obj = @unwrap-objects(body) 
        for o in obj
            notify-targets.push(o.build-target)
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


                bt = path.normalize("#dname/#{o.orig-dir}/#{o.dest-name}")

                @create-target(bt, 
                          "#{o.build-target}", 
                          "@mkdir -p #dname/#{o.orig-dir}", 
                          "cp #{o.build-target} $@")

                o.build-target = bt 

            else
                console.error "Skipping #{o.build-target} 'cause no original dir can be found"
                console.error "You might use `dest` for those files."
        return obj

    forever-watch: (dname, opts) ->

        if not opts?.root?
            throw "Please specify a root for forever to work"

        cmd = "forever #{opts.root} -w --watchDirectory #{dname}"

        if opts?.ignore?
            cmd = "#cmd --watchIgnore #{opts.ignore}"

        run-target = "run-#{@get-tmp()}"
        @create-phony-target(run-target, "",  cmd)
        return { build-target: run-target}

    add-plugin: (name, action) ~>
        @[name] = action.bind(@)

    #            _                        _ 
    #   _____  _| |_ ___ _ __ _ __   __ _| |
    #  / _ \ \/ / __/ _ \ '__| '_ \ / _` | |
    # |  __/>  <| ||  __/ |  | | | | (_| | |
    #  \___/_/\_\\__\___|_|  |_| |_|\__,_|_|


    compile-files: (action, ext, g, local-deps) ~>
        files = glob.sync(g)

        if local-deps? 
            local-deps := glob.sync(local-deps)
        else 
            local-deps := []

        dfiles = files.map ~>
            dds = local-deps.slice()
            finfo = @create-leaf-product(it, ext)
            if not (it in dds)
                dds.push(it)
            @create-target("#{finfo.build-target}", "#{dds * ' '}", action.bind(@)(finfo))
            add-deps(dds)        
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
    debug "Generating makefile"
    reset-makefile()

    bb = new Box
    require('./plugin').apply(bb)
    b.apply(bb)
    if not cb?
        fs.writeFileSync('makefile', makefile)
    else
        fs.writeFile('makefile', makefile, cb)

    if command != ""
        shelljs.exec "make #command -j", {silent: silent}, ->
            debug "Make done"
       

    watch-sources := deps 

watch-source-files = (cb) ->
        debug "First build completed"
        Gaze = require('gaze').Gaze;

        watch-sources := watch-sources.map ~>
            path.resolve(it)

        gaze = new Gaze(watch-sources);

        gaze.on 'ready', ->
            debug "Watching sources. #{watch-sources.length}"

        gaze.on 'all', cb

watch-dest-files = (cb) ->
        debug "First build completed"
        Gaze = require('gaze').Gaze;

        notify-targets := notify-targets.map ~>
            path.resolve(it)

        gaze = new Gaze(notify-targets);

        gaze.on 'ready', ->
            debug "Watching destinations. #{notify-targets.length}"

        gaze.on 'all', cb

parse-watch = (b) ->

    parse(b)

    notify-targets := notify-targets.map ~>
        path.resolve(it) 

    start-livereload()    

    if command == ""
        command := all

    shelljs.exec 'make all -j', {silent: silent}, ->
        watch-source-files (event, filepath) ->
            debug "Received #event for #filepath"
            if event == 'changed'
                shelljs.exec "make #command -j",  ->
            else
                debug "Added/changed file #filepath"
                parse b, -> 
                    shelljs.exec 'make #command -j -j', {+silent}, ->
                        debug "Make done"

        watch-dest-files (event, filepath) ->
            notify-change filepath




#  _ _                    _                 _ 
# | (_)_   _____ _ __ ___| | ___   __ _  __| |
# | | \ \ / / _ \ '__/ _ \ |/ _ \ / _` |/ _` |
# | | |\ V /  __/ | |  __/ | (_) | (_| | (_| |
# |_|_| \_/ \___|_|  \___|_|\___/ \__,_|\__,_|


LIVERELOAD_PORT = 35729;

var lr
start-livereload = ->
   lr := require('tiny-lr')()
   debug lr
   lr.listen(LIVERELOAD_PORT)

notifyChange = (path, cb) ->
  fileName = require('path').relative(notify-strip-string, path)
  debug("Notifying Livereload for a change to #fileName")
  reset = ->
     lr.changed body: { files: [fileName] }
     cb?()
  set-timeout reset, 1


_       = require('underscore')
_.str   = require('underscore.string');
moment  = require 'moment'
fs      = require 'fs'
color   = require('ansi-color').set
os      = require('os')
shelljs = require('shelljs')
table   = require('ansi-color-table')

_.mixin(_.str.exports());
_.str.include('Underscore.string', 'string');

name        = "newmake"
description = "A tiny make helper"
author      = "Vittorio Zaccaria"
year        = "2014"

info = (s) ->
  console.log color('inf', 'bold')+": #s"

err = (s) ->
  console.log color('err', 'red')+": #s"

warn = (s) ->
  console.log color('wrn', 'yellow')+": #s"

src = __dirname
otm = if (os.tmpdir?) then os.tmpdir() else "/var/tmp"
cwd = process.cwd()

setup-temporary-directory = ->
    name = "tmp_#{moment().format('HHmmss')}_tmp"
    dire = "#{otm}/#{name}" 
    shelljs.mkdir '-p', dire
    return dire

remove-temporary-directory = (dir) ->
    shelljs.rm '-rf', dir 
    
usage-string = """

#{color(name, \bold)}. #{description}
(c) #author, #year

Usage: #{name} [--option=V | -o V] 
"""

require! 'optimist'

argv     = optimist.usage(usage-string,
              watch:
                alias: 'w', description: 'watch and rebuild', boolean: true, default: false

              silent:
                alias: 's', description: 'silent mode', boolean: true, default: false

              help:
                alias: 'h', description: 'this help', default: false

                         ).boolean(\h).argv


if(argv.help)
  optimist.showHelp()
  process.exit(0)
  return

command := argv._[0] if argv._?[0]?
silent := argv.silent

if argv.watch
    module.exports = {
        parse: parse-watch
    }
else
    module.exports = {
        parse: parse
    }







