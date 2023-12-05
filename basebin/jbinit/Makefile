TARGET = jbinit

CC = clang

CFLAGS = -framework Foundation -framework CoreServices -framework IOKit -I./src/_shared -isysroot $(shell xcrun --sdk iphoneos --show-sdk-path) -arch arm64 -miphoneos-version-min=15.0
LDFLAGS = -lbsm 

sign: $(TARGET)
	codesign -f -s - --timestamp=none --all-architectures --entitlements ./entitlements.plist -i com.apple.jbinit --deep $<
	mv jbinit ../../binaries
	rm ../../binaries/jb.tc
	trustcache create -v $(TRUSTCACHEVERSION) ../../binaries/jb.tc ../../binaries

$(TARGET): $(wildcard src/*.m)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

clean:
	@rm -f $(TARGET)