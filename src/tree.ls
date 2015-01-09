"use strict"; 

TreeModel = require('tree-model')
debug     = require('debug')('tree')
uid       = require('uid')
_         = require('lodash')
tree      = new TreeModel()
emptyNode = -> tree.parse({})

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
        @curNode.addChild(tree.parse({cmd-fun: cmd, product-fun: product, src: src, deps: deps, targetName: "c-#{uid(8)}", type: "compile", children: [] }))

    processFiles: (cmd, product, body) ~>
        root = @createTree(body)
        _.extend(root.model, {cmd-fun: cmd, product-fun: product, targetName: "p-#{uid(8)}", type: "process"})
        @curNode.addChild(root)

    _collect: (name, body, options) ~>  
        debug "Creating #name"
        root = @createTree(body)
        _.extend(root.model, { targetName: name, options: options, type: "collect" })
        @curNode.addChild(root)

    collect: (name, body) ~>
        @_collect(name, body, {})

    collectSeq: (name, body) ~>
        @_collect(name, body, {+sequential})

    parse: (body) ~>
        @curNode = @createTree(body)
        _.extend(@curNode.model, { targetName: "root", type: "root" })


parse = (body) ->
    tb = new treeBuilder()
    tb.parse(body)
    return tb.curNode

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

mapProducts = (r) ->
    r.walk {strategy: 'post'}, (node) ->
        products = []
        let @=node.model 
            if @type == "compile"
                @products = [ @product-fun({source: s}) for s in @src ]
            else 
                if @type == "process"
                    cproducts = _.flatten(@children.map (.products))
                    @products = [ @product-fun({source: s}) for s in _.flatten(@children.map (.products)) ]
                else
                    if @type == "root"
                        cproducts = _.flatten(@children.map (.products))
                        @products = cproducts



transcript = (r) ->

    removeAll r, (n) ->
        n.model.type == "collect"

    mapProducts r

    r.walk {strategy: 'post'}, (node) ->
        console.log print-target(node)


print-target = (node) ->
    let @=node.model
        """ 
            #{@targetName} [ #{@type} ] depends on #{(@children.map (.targetName)) * ' '} - products #{@products * ','}
        """


module.exports = {
    parse: parse 
    transcript: transcript
    }





