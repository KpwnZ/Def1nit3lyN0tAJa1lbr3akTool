TARGET = systemhook.dylib
CC = clang

CFLAGS = -I../_shared -I./src -isysroot $(shell xcrun --sdk iphoneos --show-sdk-path) -arch arm64 -miphoneos-version-min=15.0 -Wno-deprecated-declarations -Os -moutline -framework Foundation
LDFLAGS = -dynamiclib

$(TARGET): $(wildcard src/*.m src/*.c)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^
	codesign -f -s - --timestamp=none --all-architectures --deep $@
	mv systemhook.dylib ../../binaries16
	rm ../../binaries16/jb.tc
	trustcache create -v $(TRUSTCACHEVERSION) ../../binaries16/jb.tc ../../binaries16
	
clean:
	@rm -f $(TARGET)
