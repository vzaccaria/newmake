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

.build/4-entry.js: src/assets/js/entry.ls
	lsc -p -c src/assets/js/entry.ls > .build/4-entry.js

.build/concat-tmp3.js: .build/4-entry.js
	cat $^ > $@

_site/assets/js: 
	mkdir -p _site/assets/js

_site/assets/js/client.js: .build/concat-tmp3.js _site/assets/js
	cp .build/concat-tmp3.js $@

.PHONY : client
client: _site/assets/css/client.css _site/assets/images/image.png _site/assets/js/client.js

.build/5-x.js: src/server/x.ls
	lsc -p -c src/server/x.ls > .build/5-x.js

.build/6-y.js: src/server/y.ls
	lsc -p -c src/server/y.ls > .build/6-y.js

_site/server/js/x.js: .build/5-x.js
	@mkdir -p _site/server/js/
	cp .build/5-x.js $@

_site/server/js/y.js: .build/6-y.js
	@mkdir -p _site/server/js/
	cp .build/6-y.js $@

.PHONY : server
server: _site/server/js/x.js _site/server/js/y.js

.PHONY : all
all: client server

.PHONY : clean-7
clean-7: 
	rm -rf .build/1-m.css .build/concat-tmp0.css _site/assets/css _site/assets/css/client.css .build/2-image.png _site/assets/images/image.png .build/4-entry.js .build/concat-tmp3.js _site/assets/js _site/assets/js/client.js .build/5-x.js .build/6-y.js _site/server/js/x.js _site/server/js/y.js

.PHONY : clean-8
clean-8: 
	rm -rf .build

.PHONY : clean-9
clean-9: 
	mkdir -p .build

.PHONY : clean
clean: clean-7 clean-8 clean-9
