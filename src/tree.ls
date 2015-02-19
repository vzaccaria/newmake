"use strict"; 

TreeModel = require('tree-model')
debug     = require('debug')('tree')
uid       = require('uid')
_         = require('lodash')
tree      = new TreeModel()
emptyNode = -> tree.parse({})


# Each node model has the following properties
#
# @type     = model's type
# @sources  = input files, if any (compact form)
# @products = output files, if any
# @builds   = how each file in @sources is converted to a file in @products
#             Each item in @builds has:
#             - product:        the name of the product
#             - command:        the command to use to generate it
#             - source:         the name of the source
#             - deps:           optional dependencies of this file

mapProducts = (r) ->
    r.walk {strategy: 'post'}, (node) ->
        products = []
        let @=node.model 
            if @type in [ "compile", "process", "move" ]
                if @type == "process" or @type == "move"
                    @sources = _.flatten(@children.map (.products))    

                if @type == "move"
                    if not @options.strip? 
                        @product-fun = (s) -> "#{@destination}/#{s.source}"
                    else 
                        @product-fun = (s) -> "#{@destination}/#{s.source.replace(@options.strip, "")}"
                    @cmd-fun = (_) -> "cp #{_.source} #{_.product}"

                build-from = ~> 
                    prod = @product-fun({source: it})
                    return 
                        command: @cmd-fun({source: it, product: prod})
                        product: prod
                        source: it
                        deps: @deps

                @builds   = [  build-from(s) for s in _.flatten(@sources) ]
                @products = _.map(@builds, (.product)) 

            if @type == "reduce"
                @sources = _.flatten(@children.map (.products)) 
                prod = @product-fun({})
                build = {
                    command: @cmd-fun({sources: @sources, product: prod})
                    product: prod
                    deps: @sources
                } 
                @products = [ build.product ]
                @builds = [ build ]

            if @type == "root"
                @products = _.flatten(@children.map (.products))


getAllProducts = (r) ->
    mapProducts(r)
    prod = {}
    r.walk {strategy: 'post'}, (node) ->
        let @=node.model 
            for p in @products
                prod[p] = true 
    return _.keys(prod)             

getTargetsConditional = (r, c) ->
    targets = {}
    r.walk {strategy: 'post'}, (node) ->
        let @=node.model 
            if c(@) 
                names = _.flatten(@children.map (.targetName))
                targets[@targetName] = names
    return targets 

getPhonyTargets = (r) ->
    return getTargetsConditional(r, -> it.type == "collect")

getAllTargets = (r) ->
    return r.all (-> it.type != "collect")


removeFirst = (root, condition) ->
    x = root.first(condition) 
    if x? and (x.model.target-name != root.target-name)
        father = x.parent
        for c in x.children 
            father.addChild(c)
        x.drop()
        return true
    else 
        return false

removeAll = (root, condition) ->
    do
        null
    while removeFirst(root, condition)    

class treeBuilder 

    -> 
        @curNode = emptyNode!
        @curNode.model.targetName = "root"
        @curNode.model.type = "root"

    createTree: (body) ~>
        newNode = emptyNode!
        savedCurNode = @curNode
        @curNode = newNode
        body.apply(@, [ @ ])
        @curNode = savedCurNode 
        debug newNode
        newNode.model.children = newNode.children.map (.model)
        return newNode

    compileFiles: (cmd, product, src, deps) ~>
        src = [ src ]
        deps ?= []
        @curNode.addChild(tree.parse({cmd-fun: cmd, product-fun: product, sources: src, deps: deps, targetName: "c-#{uid(8)}", type: "compile", children: [] }))

    processFiles: (cmd, product, body) ~>
        root = @createTree(body)
        _.extend(root.model, {cmd-fun: cmd, product-fun: product, targetName: "p-#{uid(8)}", type: "process", deps: []})
        @curNode.addChild(root)

    reduceFiles: (cmd, product, body) ~>
        root = @createTree(body)
        _.extend(root.model, {cmd-fun: cmd, product-fun: product, targetName: "r-#{uid(8)}", type: "reduce", deps: []})
        @curNode.addChild(root)

    _collect: (name, body, options) ~>  
        debug "Creating #name"
        root = @createTree(body)
        _.extend(root.model, { targetName: name, options: options, type: "collect" })
        @curNode.addChild(root)

    collect: (name, body) ~>
        @_collect(name, body, {})

    mirrorTo: (name, options, body) ~>
        if _.is-function(options)
            body = options
            options = {}
        root = @createTree(body) 
        _.extend(root.model, {type: "move", options: options, destination: name, targetName: "m-#{uid(8)}", deps: []})
        @curNode.addChild(root)

    collectSeq: (name, body) ~>
        @_collect(name, body, {+sequential})

    parse: (body) ~>
        @curNode = @createTree(body)
        _.extend(@curNode.model, { targetName: "root", type: "root" })
        @phonyTargets = getPhonyTargets(@curNode)
        removeAll @curNode, (n) ->
                n.model.type == "collect"
        @allProducts = getAllProducts(@curNode)
        @allTargets = getAllTargets(@curNode)
        @root = @curNode

    # dot: ~>
    #     @root.walk {strategy: 'post'}, (node) ->
    #         console.log node.model.targetName 

    addPack: (pack) ~>
        for k,v of pack
            @[k] = v.bind(@)

parse = (body) ->
    tb = new treeBuilder()
    tb.parse(body)
    return tb


module.exports = {
    parse: parse 
}





