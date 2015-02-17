.DEFAULT_GOAL := all

.build/0-treeTest.js: src/treeTest.js6
	6to5 src/treeTest.js6 -o .build/0-treeTest.js

.build/1-index.js: src/index.ls
	lsc -p -c src/index.ls > .build/1-index.js

.build/2-nmake.js: src/nmake.ls
	lsc -p -c src/nmake.ls > .build/2-nmake.js

.build/3-plugin.js: src/plugin.ls
	lsc -p -c src/plugin.ls > .build/3-plugin.js

.build/4-screen.js: src/screen.ls
	lsc -p -c src/screen.ls > .build/4-screen.js

.build/5-tree.js: src/tree.ls
	lsc -p -c src/tree.ls > .build/5-tree.js

.build/6-web.js: src/packs/web.ls
	lsc -p -c src/packs/web.ls > .build/6-web.js

.build/7-make.js: src/backends/make.ls
	lsc -p -c src/backends/make.ls > .build/7-make.js

lib/treeTest.js: .build/0-treeTest.js
	@mkdir -p ./lib/
	cp .build/0-treeTest.js $@

lib/index.js: .build/1-index.js
	@mkdir -p ./lib/
	cp .build/1-index.js $@

lib/nmake.js: .build/2-nmake.js
	@mkdir -p ./lib/
	cp .build/2-nmake.js $@

lib/plugin.js: .build/3-plugin.js
	@mkdir -p ./lib/
	cp .build/3-plugin.js $@

lib/screen.js: .build/4-screen.js
	@mkdir -p ./lib/
	cp .build/4-screen.js $@

lib/tree.js: .build/5-tree.js
	@mkdir -p ./lib/
	cp .build/5-tree.js $@

lib/packs/web.js: .build/6-web.js
	@mkdir -p ./lib//packs
	cp .build/6-web.js $@

lib/backends/make.js: .build/7-make.js
	@mkdir -p ./lib//backends
	cp .build/7-make.js $@

.PHONY : cmd-8
cmd-8: 
	cp ./lib/index.js .

.PHONY : cmd-seq-9
cmd-seq-9: 
	make lib/treeTest.js
	make lib/index.js
	make lib/nmake.js
	make lib/plugin.js
	make lib/screen.js
	make lib/tree.js
	make lib/packs/web.js
	make lib/backends/make.js
	make cmd-8

.PHONY : build
build: cmd-seq-9

.PHONY : cmd-10
cmd-10: 
	make build

.PHONY : cmd-11
cmd-11: 
	node lib/treeTest.js

.PHONY : cmd-seq-12
cmd-seq-12: 
	make cmd-10
	make cmd-11

.PHONY : all
all: cmd-seq-12
