"use strict"; 

TreeModel = require('tree-model')
debug     = require('debug')('tree')
uid       = require('uid')
_         = require('lodash')
tree      = new TreeModel()
emptyNode = -> tree.parse({})

class treeBuilder 

    -> 
        @cur-node = tree.parse {+root}

    collect: (name, body, options) ~>  
        debug "Creating #name"
        t = @create-tree(body)
        t.model.target-name = name
        t.model.options = options
        @cur-node.addChild(t)

    create-tree: (body) ~>
        new-node = emptyNode!
        saved-cur-node = @cur-node
        @cur-node = new-node
        body.apply(@, [ @ ])
        @cur-node = saved-cur-node 
        debug new-node
        return new-node


    compileFiles: (cmd, src, deps) ~>
        debug("Compile #src")
        @cur-node.addChild(tree.parse(cmd: cmd, src: src, deps: deps, targetName: "c-#{uid(8)}"))

    processFiles: (cmd, ext, body) ~>
        t = @create-tree(body)
        t.model = { cmd: cmd, ext: ext, targetName: "p-#{uid(8)}" }
        @cur-node.addChild(t)

    parse: (body) ~>
        t = @create-tree(body)
        @cur-node = t 
        @cur-node.model.root = true

parse = (body) ->
    tb = new treeBuilder()
    tb.parse(body)
    return tb

dump = (tb) ->
    tb.cur-node.walk {strategy: 'post'}, (node) ->
        console.log node.model

getTargets = (tb, node) ->
    ts = []
    var starting-node
    if not node?
        starting-node := tb.cur-node
    else
        if _.is-string(node)
            starting-node := tb.cur-node.first (n) ->
                n.model.targetName == node 
        else
            starting-node := node 

    starting-node.walk {strategy: 'post'}, (node) ->
        if node.model.targetName?
            ts := ts ++ [ node.model.targetName ]

    return ts

transcript = (tb) ->
    t = getTargets(tb)
    for x in t
        console.log "Target #x depends on #{getTargets(tb, x)}"

module.exports = {
    parse: parse 
    getTargets: getTargets 
    transcript: transcript
    }





