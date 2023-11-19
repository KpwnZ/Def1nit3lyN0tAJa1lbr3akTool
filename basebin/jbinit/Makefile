TARGET = jbinit

CC = clang

CFLAGS = -framework Foundation -framework CoreServices -framework IOKit -I./src/_shared -isysroot $(shell xcrun --sdk iphoneos --show-sdk-path) -arch arm64 -miphoneos-version-min=15.0
LDFLAGS = -lbsm 

sign: $(TARGET)
	@ldid -Sentitlements.plist -Icom.apple.jbinit $<
	cp jbinit ../../binaries
	rm ../../binaries/jb.tc
	trustcache create ../../binaries/jb.tc ../../binaries

$(TARGET): $(wildcard src/*.m)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

clean:
	@rm -f $(TARGET)