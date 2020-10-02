# Remember to customize variables below before making a release.  See README.md
# for details.

# short game name used for the executable and the release archives names.  No
# spaces.
GAME=gameStub
# Full title.  Can contain spaces.
FULLNAME=Game Stub
# Used for itch.io releases.  Remember to bump.
VERSION=0.0.1
# Used to upload builds to itch.io.  Optional.
ITCHUSER=

CC=clang

SRC=$(shell find src/ -name '*.hx' -type f)
TEST=$(shell find test/ -name '*.hx' -type f)
HXML=$(wildcard hxml/*.hxml)
RES=$(shell find res/* -type f)
ARCHIVES=release/$(GAME)-html5.zip release/$(GAME)-win.zip \
	release/$(GAME)-x86_64.tar.gz release/$(GAME)-osx.zip
ICONS=$(wildcard dist/icons/*.png)

all: devel.hl

devel.hl: bin/devel.hl
devel.js: bin/devel.js index.html
release.hl: bin/release.hl
release.js: bin/release.js

run.hl: bin/devel.hl
	hl bin/devel.hl

run.js: bin/devel.js
	xdg-open index.html

run.release.hl: bin/release.hl
	cd bin; hl release.hl

test.hl: bin/devel.hl $(TEST)
	haxe hxml/test.hl.hxml

test.js: bin/devel.js $(TEST)
	haxe hxml/test.js.hxml

bin/devel.hl: $(SRC) $(HXML) $(RES)
	haxe hxml/devel.hl.hxml

bin/devel.js: $(SRC) $(HXML) $(RES)
	haxe hxml/devel.js.hxml

bin/release.hl: $(SRC) $(HXML) bin/res.pak
	git diff-index --quiet HEAD -- || (echo "Can't create release build in dirty tree" && exit 1)
	haxe hxml/release.hl.hxml

bin/release.js: $(SRC) $(HXML) bin/res.pak
	git diff-index --quiet HEAD -- || (echo "Can't create release build in dirty tree" && exit 1)
	haxe hxml/release.js.hxml

bin/res.pak: $(RES)
	haxe -hl hxd.fmt.pak.Build.hl -lib heaps -main hxd.fmt.pak.Build
	hl hxd.fmt.pak.Build.hl
	mkdir -p bin
	mv res.pak bin/res.pak

release/$(GAME)-html5.zip: bin/release.js dist/html5/index.html
	mkdir -p release/$(GAME)-html5/bin
	cp -r dist/html5/* release/$(GAME)-html5
	sed -e "s/FULLNAME/$(FULLNAME)/g" -e "s/GAME/$(GAME)/g" -i release/$(GAME)-html5/index.html
	cp bin/release.js release/$(GAME)-html5/bin/$(GAME).js
	cd release/$(GAME)-html5; zip -r $(GAME)-html5.zip .
	mv release/$(GAME)-html5/$(GAME)-html5.zip release

release/$(GAME)-win.zip: bin/release.hl
	mkdir -p release/$(GAME)-win/bin
	cp -r dist/win/* release/$(GAME)-win
	cp bin/release.hl release/$(GAME)-win/bin/hlboot.dat
	mv release/$(GAME)-win/launcher.exe release/$(GAME)-win/$(GAME).exe
	cp bin/res.pak release/$(GAME)-win/bin/
	cd release; zip -r $(GAME)-win.zip $(GAME)-win

release/$(GAME)-x86_64.tar.gz: bin/release.hl
	mkdir -p release/$(GAME)-x86_64/bin
	cp -r dist/x86_64/* release/$(GAME)-x86_64
	cp bin/release.hl release/$(GAME)-x86_64/bin/hlboot.dat
	mv release/$(GAME)-x86_64/GAME.sh release/$(GAME)-x86_64/$(GAME).sh
	cp bin/res.pak release/$(GAME)-x86_64/bin/
	cd release; tar zcf $(GAME)-x86_64.tar.gz $(GAME)-x86_64

dist/icons/icon.icns: $(ICONS)
	cd dist/icons; png2icns icon.icns icon_*.png

release/$(GAME)-osx.zip: bin/release.hl dist/icons/icon.icns
	mkdir -p release/$(GAME)-osx/$(GAME).app
	cp -r dist/osx/* release/$(GAME)-osx/$(GAME).app
	cp bin/release.hl release/$(GAME)-osx/$(GAME).app/Contents/MacOs/hlboot.dat
	mv release/$(GAME)-osx/$(GAME).app/Contents/MacOs/GAME release/$(GAME)-osx/$(GAME).app/Contents/MacOs/$(GAME)
	sed -e "s/FULLNAME/$(FULLNAME)/g" -e "s/GAME/$(GAME)/g" -e "s/VERSION/$(VERSION)/g" -i release/$(GAME)-osx/$(GAME).app/Contents/Info.plist
	cp dist/icons/icon.icns release/$(GAME)-osx/$(GAME).app/Contents/Resources
	cp bin/res.pak release/$(GAME)-osx/$(GAME).app/Contents/MacOs/
	cd release/$(GAME)-osx; zip -r ../$(GAME)-osx.zip $(GAME).app

bin/release_src/main.c: $(SRC) $(HXML) $(RES)
	haxe hxml/release.hl.c.hxml

release/$(GAME)-native-x86_64.tar.gz: bin/release_src/main.c
	mkdir -p release/$(GAME)-native-x86_64/bin
	cp -r dist/x86_64/* release/$(GAME)-native-x86_64
	cp dist/x86_64/bin/*.hdll .
	$(CC) -O3 -o bin/$(GAME) -std=c17 -I bin/release_src bin/release_src/main.c *.hdll -lhl -lSDL2 -lopenal -lm -lGL
	rm *.hdll
	cp bin/$(GAME) release/$(GAME)-native-x86_64/bin/hl
	mv release/$(GAME)-native-x86_64/GAME.sh release/$(GAME)-native-x86_64/$(GAME).sh
	cd release; tar zcf $(GAME)-native-x86_64.tar.gz $(GAME)-native-x86_64

dist/armv7l/bin/hl: $(SRC) $(HXML) $(RES)
	echo "Compile contents of \"bin/release_src\" on Raspberry Pi and save the resulting executable as dist/armv7l/bin/hl"
	exit 1

release/$(GAME)-armv7l.tar.gz: bin/release_src/main.c dist/armv7l/bin/hl
	mkdir -p release/$(GAME)-armv7l/bin
	cp -r dist/armv7l/* release/$(GAME)-armv7l
	mv release/$(GAME)-armv7l/GAME.sh release/$(GAME)-armv7l/$(GAME).sh
	cp dist/armv7l/bin/hl release/$(GAME)-armv7l/bin/hl
	cd release; tar zcf $(GAME)-armv7l.tar.gz $(GAME)-armv7l

release: $(ARCHIVES)

linux-native: release/$(GAME)-native-x86_64.tar.gz

arm-native: release/$(GAME)-armv7l.tar.gz

upload: $(ARCHIVES)
	butler push release/$(GAME)-html5  $(ITCHUSER)/$(GAME):html  --userversion $(VERSION)
	butler push release/$(GAME)-win    $(ITCHUSER)/$(GAME):win   --userversion $(VERSION)
	butler push release/$(GAME)-x86_64 $(ITCHUSER)/$(GAME):linux --userversion $(VERSION)
	butler push release/$(GAME)-osx    $(ITCHUSER)/$(GAME):osx   --userversion $(VERSION)

upload-arm: release/$(GAME)-armv7l.tar.gz
	butler push release/$(GAME)-armv7l $(ITCHUSER)/$(GAME):arm x  --userversion $(VERSION)

clean:
	rm -rf bin/ release/ dist/icons/icon.icns res.pak hxd.fmt.pak.Build.hl

.PHONY: all clean release linux-native arm-native upload upload-arm devel.hl \
	devel.js run.hl run.js release.hl release.js test.hl test.js
