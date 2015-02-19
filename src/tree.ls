"use strict"; 

TreeModel = require('tree-model')
debug     = require('debug')('tree')
uid       = require('uid')
_         = require('lodash')

{ phony, product, targetStore } = require('./file')

tree      = new TreeModel()
emptyNode = -> tree.parse({})

createBuildTarget = (node, source) ->
    # debug "/createBuildTarget: building from model #{JSON.stringify(node.model, 0,4)}"
    let @=node.model
         productName = @product-fun({source: source})
         commandName = @cmd-fun({source: source, product: productName, sources: @sources, deps: @deps})
         f = new product(productName, source, commandName, [source] ++ @deps)
         return f


processCompileNode = (node) ->
    let @=node.model
        buildTargets = _.map _.flatten(@sources), (source) ->
            createBuildTarget(node, source)

        @products = _.map(buildTargets, (.name))
        buildTargets = buildTargets ++ (new phony(@targetName, @products, {} ))
        return buildTargets 


processPostProcessNode = (node) ->
    let @=node.model
        @sources    = _.flatten(@children.map (.products))
        return processCompileNode(node)


processReduceNode = (node) ->
    let @=node.model
        debug "reduceNode name", @
        @deps       = _.flatten(@children.map (.products))
        return processPostProcessNode(node)


processCollectNode = (node) ->
    let @=node.model
        debug "CollectNode name", @
        @deps     = _.flatten(@children.map (.targetName))
        @products = _.flatten(@children.map (.products))
        return (new phony(@targetName, @deps, @options))


processNode = (node) ->
    let @=node.model
        buildTargets =
          | @type == "compile"                     => processCompileNode(node)
          | @type == "process"  or @type == "move" => processPostProcessNode(node)
          | @type == "reduce"                      => processReduceNode(node)
          | @type == "root"                        => []
          | @type == "collect"                     => processCollectNode(node)
          | otherwise                              => throw "Invalid type #{@type}"
        return buildTargets

mapNodes = (r, f) ->
    s = [ ]
    r.walk {strategy: 'post'}, (node) ->
        v = f(node)
        s.push(v)
    return s

processNodes = (r) ->
    nodeList = mapNodes(r, processNode)
    return _.flatten(nodeList)

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

        if not options.strip? 
            product-fun = (s) -> "#{name}/#{s.source}"
        else 
            product-fun = (s) -> "#{name}/#{s.source.replace(options.strip, "")}"

        cmd-fun = (_) -> "cp #{_.source} #{_.product}"

        _.extend(root.model, {
            type: "move", 
            options: options, 
            destination: name, 
            cmd-fun: cmd-fun
            product-fun: product-fun
            targetName: "m-#{uid(8)}", 
            deps: []})
        @curNode.addChild(root)

    collectSeq: (name, body) ~>
        @_collect(name, body, {+sequential})

    parse: (body) ~>
        @curNode = @createTree(body)
        _.extend(@curNode.model, { targetName: "root", type: "root" })
        @root = @curNode
        @createTargetStore!
        return @frame

    createTargetStore: ~>
        @frame = new targetStore()
        _.map processNodes(@root), @frame.addTarget

        return @frame

    addPack: (pack) ~>
        for k,v of pack
            @[k] = v.bind(@)

parse = (body) ->
    tb = new treeBuilder()
    return tb.parse(body)


module.exports = {
    parse: parse 
}





