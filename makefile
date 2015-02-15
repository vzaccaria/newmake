.DEFAULT_GOAL := all

.build/0-treeTest.js: src/treeTest.js
	6to5 src/treeTest.js -o .build/0-treeTest.js

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

.PHONY : cmd-6
cmd-6: 
	cp ./lib/index.js .

.PHONY : cmd-seq-7
cmd-seq-7: 
	make lib/treeTest.js
	make lib/index.js
	make lib/nmake.js
	make lib/plugin.js
	make lib/screen.js
	make lib/tree.js
	make cmd-6

.PHONY : all
all: cmd-seq-7

.PHONY : cmd-8
cmd-8: 
	make all

.PHONY : cmd-9
cmd-9: 
	node lib/treeTest.js

.PHONY : cmd-seq-10
cmd-seq-10: 
	make cmd-8
	make cmd-9

.PHONY : test
test: cmd-seq-10
