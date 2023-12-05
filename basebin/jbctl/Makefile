TARGET = jbctl

CC = clang

CFLAGS = -framework Foundation -framework CoreServices -framework Security -I../_shared -I./src -isysroot $(shell xcrun --sdk iphoneos --show-sdk-path) -arch arm64 -miphoneos-version-min=15.0 -fobjc-arc

$(TARGET): $(wildcard src/*.m)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^
	codesign -f -s - --timestamp=none --all-architectures --entitlements ./entitlements.plist --deep $<
	mv jbctl ../../binaries
	rm ../../binaries/jb.tc
	trustcache create -v $(TRUSTCACHEVERSION) ../../binaries/jb.tc ../../binaries

clean:
	@rm -f $(TARGET)