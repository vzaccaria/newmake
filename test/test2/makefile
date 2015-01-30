.DEFAULT_GOAL := all

.build/1-m.css: src/assets/css/m.less
	lessc src/assets/css/m.less .build/1-m.css

.build/concat-tmp0.css: .build/1-m.css
	cat $^ > $@

_site/assets/css: 
	mkdir -p _site/assets/css

_site/assets/css/client.css: .build/concat-tmp0.css _site/assets/css
	cp .build/concat-tmp0.css $@

.build/2-image.png: src/assets/images/image.png
	cp src/assets/images/image.png .build/2-image.png

_site/assets/images/image.png: .build/2-image.png
	@mkdir -p _site/assets/images/
	cp .build/2-image.png $@

_site/assets: 
	mkdir -p _site/assets

_site/assets/index.html: _site/assets/html/index.html _site/assets
	cp _site/assets/html/index.html $@

.build/4-entry.js: src/assets/js/entry.ls
	lsc -p -c src/assets/js/entry.ls > .build/4-entry.js

.build/concat-tmp3.js: .build/4-entry.js
	cat $^ > $@

.build/5-concat-tmp3.min.js: .build/concat-tmp3.js
	uglifyjs .build/concat-tmp3.js -c -m  > $@

_site/assets/js: 
	mkdir -p _site/assets/js

_site/assets/js/client.js: .build/5-concat-tmp3.min.js _site/assets/js
	cp .build/5-concat-tmp3.min.js $@

.build/6-index.html: src/assets/views/index.jade
	jade -p src/assets/views/index.jade < src/assets/views/index.jade > .build/6-index.html

_site/assets/html/index.html: .build/6-index.html
	@mkdir -p _site/assets/html/
	cp .build/6-index.html $@

.PHONY : client
client: _site/assets/css/client.css _site/assets/images/image.png _site/assets/index.html _site/assets/js/client.js _site/assets/html/index.html

.build/7-x.js: src/server/x.ls
	lsc -p -c src/server/x.ls > .build/7-x.js

.build/8-y.js: src/server/y.ls
	lsc -p -c src/server/y.ls > .build/8-y.js

_site/server/js/x.js: .build/7-x.js
	@mkdir -p _site/server/js/
	cp .build/7-x.js $@

_site/server/js/y.js: .build/8-y.js
	@mkdir -p _site/server/js/
	cp .build/8-y.js $@

.PHONY : server
server: _site/server/js/x.js _site/server/js/y.js

.PHONY : all
all: client server

.PHONY : clean-9
clean-9: 
	rm -rf .build/1-m.css .build/concat-tmp0.css _site/assets/css _site/assets/css/client.css .build/2-image.png _site/assets/images/image.png _site/assets _site/assets/index.html .build/4-entry.js .build/concat-tmp3.js .build/5-concat-tmp3.min.js _site/assets/js _site/assets/js/client.js .build/6-index.html _site/assets/html/index.html .build/7-x.js .build/8-y.js _site/server/js/x.js _site/server/js/y.js

.PHONY : clean-10
clean-10: 
	rm -rf .build

.PHONY : clean-11
clean-11: 
	mkdir -p .build

.PHONY : clean
clean: clean-9 clean-10 clean-11

.PHONY : cmd-12
cmd-12: 
	mocha -C --bail -t 5000 -R min src/assets//app-test.js

.PHONY : cmd-13
cmd-13: 
	mocha -C --bail -t 5000 -R min src/assets//test/acl/acl-test.js

.PHONY : cmd-14
cmd-14: 
	mocha -C --bail -t 5000 -R min src/assets//core/job-management/job-manager-test.js

.PHONY : test
test: cmd-12 cmd-13 cmd-14
