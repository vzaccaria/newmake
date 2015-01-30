.DEFAULT_GOAL := all

.build/0-index.js: ./src/index.ls
	lsc -p -c src/index.ls > .build/0-index.js

.build/1-nmake.js: ./src/nmake.ls
	lsc -p -c src/nmake.ls > .build/1-nmake.js

.build/2-plugin.js: ./src/plugin.ls
	lsc -p -c src/plugin.ls > .build/2-plugin.js

.build/3-screen.js: ./src/screen.ls
	lsc -p -c src/screen.ls > .build/3-screen.js

lib/index.js: .build/0-index.js
	@mkdir -p ./lib/
	cp .build/0-index.js $@

lib/nmake.js: .build/1-nmake.js
	@mkdir -p ./lib/
	cp .build/1-nmake.js $@

lib/plugin.js: .build/2-plugin.js
	@mkdir -p ./lib/
	cp .build/2-plugin.js $@

lib/screen.js: .build/3-screen.js
	@mkdir -p ./lib/
	cp .build/3-screen.js $@

.PHONY : cmd-4
cmd-4: 
	cp ./lib/index.js .

.PHONY : cmd-seq-5
cmd-seq-5: 
	make lib/index.js
	make lib/nmake.js
	make lib/plugin.js
	make lib/screen.js
	make cmd-4

.PHONY : all
all: cmd-seq-5

.PHONY : cmd-6
cmd-6: 
	./test/test1.sh

.PHONY : cmd-7
cmd-7: 
	./test/test2.sh

.PHONY : cmd-seq-8
cmd-seq-8: 
	make cmd-6
	make cmd-7

.PHONY : test
test: cmd-seq-8

.PHONY : cmd-9
cmd-9: 
	./node_modules/.bin/xyz --increment major

.PHONY : release-major
release-major: cmd-9

.PHONY : cmd-10
cmd-10: 
	./node_modules/.bin/xyz --increment minor

.PHONY : release-minor
release-minor: cmd-10

.PHONY : cmd-11
cmd-11: 
	./node_modules/.bin/xyz --increment patch

.PHONY : release-patch
release-patch: cmd-11
