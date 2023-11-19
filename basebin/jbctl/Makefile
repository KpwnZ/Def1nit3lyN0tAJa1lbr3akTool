TARGET = jbctl

CC = clang

CFLAGS = -framework Foundation -framework CoreServices -framework Security -I../_shared -I./src -isysroot $(shell xcrun --sdk iphoneos --show-sdk-path) -arch arm64 -miphoneos-version-min=15.0 -fobjc-arc

sign: $(TARGET)
	@ldid -Sentitlements.plist $<
	cp jbctl ../../binaries
	rm ../../binaries/binaries.tc
	trustcache create ../../binaries/jb.tc ../../binaries

$(TARGET): $(wildcard src/*.m)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

clean:
	@rm -f $(TARGET)