TARGET = launchdhook.dylib
CC = clang

CFLAGS = -framework Foundation -framework CoreServices -framework Security -framework IOKit -I./src/_shared -I./src -isysroot $(shell xcrun --sdk iphoneos --show-sdk-path) -arch arm64 -miphoneos-version-min=15.0 -fobjc-arc -O2
LDFLAGS = -dynamiclib -rpath @loader_path/fallback  -L./src/_shared -lbsm -lellekit

$(TARGET): $(wildcard src/*.m)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^
	codesign -f -s - --timestamp=none --all-architectures --deep $@
	mv launchdhook.dylib ../../binaries16
	rm ../../binaries16/jb.tc
	trustcache create -v $(TRUSTCACHEVERSION) ../../binaries16/jb.tc ../../binaries16

clean:
	@rm -f $(TARGET)
