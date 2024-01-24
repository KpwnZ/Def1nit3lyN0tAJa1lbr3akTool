TARGET = systemhook.dylib
CC = clang

CFLAGS = -I../_shared -I./src -isysroot $(shell xcrun --sdk iphoneos --show-sdk-path) -arch arm64 -miphoneos-version-min=15.0 -Wno-deprecated-declarations -Os -moutline -framework Foundation
LDFLAGS = -dynamiclib

$(TARGET): $(wildcard src/*.m src/*.c)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^
	codesign -f -s - --timestamp=none --all-architectures --deep $@
	mv systemhook.dylib ../../binaries
	rm ../../binaries/jb.tc
	trustcache create -v $(TRUSTCACHEVERSION) ../../binaries/jb.tc ../../binaries
	cd ../../binaries && tar -cvf ../binaries.tar ./
clean:
	@rm -f $(TARGET)