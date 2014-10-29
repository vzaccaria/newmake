#!/usr/bin/env lsc

_         = require('underscore')
_.str     = require('underscore.string');
glob      = require 'glob'
_         = require 'underscore'
path      = require 'path'
fs        = require 'fs'
shelljs   = require 'shelljs'
minimatch = require 'minimatch'

debug = require('debug')('normal')
hdebug = require('debug')('highlight')

_.mixin(_.str.exports());
_.str.include('Underscore.string', 'string');


targets             = []
phony-targets       = []
deps                = []
clean-targets       = []
notify-targets      = []
watch-sources       = []
notify-strip-string = ""
notifyRewrites       = []
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

    cmd: (comd) ~>
        name = "cmd-#{@get-tmp()}"
        @create-phony-target(name, "", comd)
        return { build-target: name }

    make: (maketarget) ~>
        name = "cmd-#{@get-tmp()}"
        @create-phony-target(name, "", "make maketarget")
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

    notify-rewrite: (target, glob) ~>
        notifyRewrites.push(target: target, glob: glob)

    understood: (finfo) ~>
        if not finfo.orig.ext? 
            console.log new Error().stack
            throw "Basename undefined"
        s = ""
        s = s + "\nfrom:  #{finfo.orig.base-dir} / #{finfo.orig.base-name} . #{finfo.orig.ext} ( #{finfo.orig.complete-name} ) \n" if finfo.orig
        s = s + "to:    #{finfo.prod.base-dir} / #{finfo.prod.base-name} . #{finfo.prod.ext} ( #{finfo.prod.complete-name} ) \n" if finfo.prod
        return s


    get-source-deps: (array) ~>
        original-files = @unwrap-objects(array)
        deps = original-files.map ->
            return it.prod.complete-name if it.prod?.complete-name?
            return it.build-target if it.build-target?
            return ""
        return  deps * ' '

    finalize: (finfo) ~>
        finfo.build-target  = finfo.prod.complete-name
        finfo.orig-complete = finfo.orig.complete-name   
        return finfo

    change-extension: (newext, prev-finfo) ~~>
        debug "change extension"
        debug prev-finfo
        finfo = { orig: prev-finfo.prod, prod: {}}
        finfo.prod.complete-name = path.normalize "#{finfo.orig.base-dir}/#{finfo.orig.base-name}#newext"
        finfo.prod.ext           = newext
        finfo.prod.base-name     = path.basename(finfo.prod.complete-name, finfo.prod.ext)
        finfo.prod.base-dir      = finfo.orig.base-dir

        return @finalize(finfo)

    change-folder: (folder, prev-finfo) ~~>
        finfo = { orig: prev-finfo.prod, prod: {}}
        finfo.prod.complete-name = path.normalize "#{folder}/#{finfo.orig.base-name}#{finfo.orig.ext}"
        finfo.prod.ext           = finfo.orig.ext
        finfo.prod.base-name     = path.basename(finfo.prod.complete-name, finfo.prod.ext)
        finfo.prod.base-dir      = folder

        return @finalize(finfo)

    prefix-name: (prefix, prev-finfo) ~~>
        finfo = { orig: prev-finfo.prod, prod: {}}
        finfo.prod.complete-name = path.normalize "#{finfo.orig.base-dir}/#prefix-#{finfo.orig.base-name}#{finfo.orig.ext}"
        finfo.prod.ext           = finfo.orig.ext
        finfo.prod.base-name     = path.basename(finfo.prod.complete-name, finfo.prod.ext)
        finfo.prod.base-dir      = finfo.orig.base-dir
        debug @understood(finfo)

        return @finalize(finfo)    


    from-name: (name) ~>
        finfo                    = { orig: {}, prod: {} }
        finfo.prod.complete-name = path.normalize "#name"
        finfo.prod.ext           = path.extname(finfo.prod.complete-name)
        finfo.prod.base-name     = path.basename(finfo.prod.complete-name, finfo.prod.ext)
        finfo.prod.base-dir      = path.dirname(finfo.prod.complete-name)       
        return @finalize(finfo)

    create-leaf-product: (original-file-name, newext) ~>
        finfo = { orig: @from-name(original-file-name).prod }
        newext ?= finfo.orig.ext
        finfo.prod = (@from-name(original-file-name) |> @change-extension(newext) |> @prefix-name(@get-tmp()) |> @change-folder(@build-dir)).prod
        return @finalize(finfo)

    create-reduction-product: (prod-name) ~>
        @from-name("#{@build-dir}/#prod-name")

    create-processed-product: (orig, newext, target-dir) ~>
        orig-prod   = orig.prod 
        final-prod  = (orig |> @change-extension(newext) |> @prefix-name(@get-tmp()) |> @change-folder(@build-dir)).prod
        finfo = { orig: orig-prod, prod: final-prod}
        return @finalize(finfo)

    create-root-product-to-dir: (dir, name, ext, orig) ~>
        finfo      = { orig: orig }
        finfo.prod = @from-name("#dir/#name#ext").prod
        return @finalize(finfo)

    create-root-product-dest: (whole-name, orig) ~>
        finfo      = { orig: orig }
        finfo.prod = @from-name(whole-name).prod
        return @finalize(finfo)


    get-tmp: ~>
        @tmp = @tmp + 1
        return @tmp - 1

    dest: (dname, body) ~>
        obj = @unwrap-objects(body)
        if obj.length > 1 or obj.length == 0
            throw "Sorry, `dest` can receive a single file only.."

        o = obj[0]

        dir     = @prepare-dir(dname)
        finfo   = @create-root-product-dest(dname, o.prod)
        @create-target(dname, "#{finfo.orig.complete-name} #dir", "cp #{finfo.orig.complete-name} $@")

        return finfo 



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
        hdebug "Unrapped"
        hdebug obj
        return obj.map (o) ~>
                debug "Considering destination #dname"
                debug o
                if not _.isEmpty(o.prod)

                    base-dir-stripped = o.orig.base-dir
                    base-dir-stripped = base-dir-stripped.replace(options.strip, '') if options?.strip?

                    dir  = "#dname/#base-dir-stripped"
                    name = o.orig.base-name
                    ext  = o.prod.ext

                    finfo = @create-root-product-to-dir(dir, name, ext, o.prod)

                    # debug "Final target:"
                    # debug finfo
                    @create-target(finfo.prod.complete-name, 
                              "#{o.prod.complete-name}", 
                              "@mkdir -p #dir", 
                              "cp #{o.prod.complete-name} $@")

                    return finfo
                else
                    throw "Skipping #{o.build-target} 'cause no original dir can be found\n You might use `dest` for those files."

    forever-watch: (dname, opts) ->

        if not opts?.root?
            throw "Please specify a root for forever to work"

        cmd = "forever -w --watchDirectory #{dname} #{opts.root}"

        if opts?.ignore?
            cmd = "#cmd --watchIgnore #{opts.ignore}"

        run-target = "run-#{@get-tmp()}"
        @create-phony-target(run-target, "",  cmd)
        return { build-target: run-target}

    add-plugin: (name, action) ~>
        @[name] = action.bind(@)

    file-escape: (it) -> it.replace(/'/, '\\\'')


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

        files = files.map (@file-escape)

        dfiles = files.map ~>
            dds = local-deps.slice()

            finfo = @create-leaf-product(it, ext)

            if not (it in dds)
                dds.push(it)

            debug "Compiling files.."
            @create-target("#{finfo.build-target}", "#{dds * ' '}", action.bind(@)(finfo))
            add-deps(dds)        
            return finfo                                          

    reduce-files: (action, new-name, ext, array) ~>
        finfo = @create-reduction-product("#new-name#{@get-tmp()}.#ext")
        debug "Created reduction product"
        debug finfo
        deps = @get-source-deps(array)
        @create-target(finfo.build-target, deps, action)
        return finfo        

    process-files: (action, ext, array) ~>
        files = @unwrap-objects(array)
        dfiles = files.map ~>
            debug it
            finfo = @create-processed-product(it, ext)
            @create-target(finfo.build-target, finfo.orig.complete-name, action.bind(@)(finfo))
            return finfo
        return dfiles

   
    command-seq: (body) ->
        commands = @unwrap-objects(body)
        names    = commands.map (.build-target)
        name     = "cmd-seq-#{@get-tmp()}"
        comd     = [ "make #i" for i in names ] * '\n\t'
        @create-phony-target(name, "", comd)
        return { build-target: name }

    collect: (name, options, array) ~>
        if not array? 
            array = options 
            options = {}


        files = @unwrap-objects(array)
        source-build-targets = @get-source-deps(files)

        if options.after?
            if _.isArray(options.after)
                source-build-targets = source-build-targets + " #{options.after * ' '}"
            else
                source-build-targets = source-build-targets + " #{options.after}"


        @create-phony-target(name, source-build-targets)

        finfo                    = { orig: {}, prod: {} }
        finfo.prod.complete-name = "#name"
        finfo.prod.ext           = "" 
        finfo.prod.base-name     = ""
        finfo.prod.base-dir      = @build-dir

        # for backward compatibility
        finfo.build-target       = finfo.prod.complete-name

        return finfo

    copy-target: (name) ~>
        finfo = { orig: {}, prod: {} }
        finfo.prod.complete-name = name
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
        command := \all

    shelljs.exec 'make all -j', {silent: silent}, ->
        watch-source-files (event, filepath) ->
            debug "Received #event for #filepath"
            if event == 'changed'
                shelljs.exec "make #command -j",  ->
            else
                debug "Added/changed file #filepath"
                parse b, -> 
                    shelljs.exec 'make #command -j', {+silent}, ->
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

notify-change = (path) ->
  fileName = require('path').relative(notify-strip-string, path)
  found = false

  delay = setTimeout(_, 100)

  for w in notifyRewrites
    let x = w
        debug "checking for #fileName, #{x.glob}"
        if minimatch fileName, x.glob
          debug("Notifying Livereload for a change to #{x.target}")
          delay ->
            lr.changed body: { files: [x.target] }
          found := true

  if not found
    delay ->
        lr.changed body: { files: [fileName] }



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







