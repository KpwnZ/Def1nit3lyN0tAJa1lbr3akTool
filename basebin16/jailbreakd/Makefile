TARGET = jailbreakd

CC = clang++

CFLAGS = -Wall -std=c++11 -framework Foundation -framework CoreServices -framework Security -framework IOKit -framework UIKit -I./_shared -I./ -I./utils -isysroot $(shell xcrun --sdk iphoneos --show-sdk-path) -arch arm64 -miphoneos-version-min=15 -fobjc-arc -Wno-nullability-completeness-on-arrays -O3
LDFLAGS = -lbsm

CFLAGS += -DVERSION_COMMIT_COUNT='" "'
CFLAGS += -DVERSION_COMMIT_SHA='" "'

sign: $(TARGET)
	codesign -f -s - --timestamp=none --all-architectures --entitlements ./entitlements.plist --deep $<
	mv $< ../../binaries16
	rm ../../binaries16/jb.tc || true
	trustcache create -v $(TRUSTCACHEVERSION) ../../binaries16/jb.tc ../../binaries16

$(TARGET): $(wildcard *.mm ./utils/*.mm ./kernel/*.mm)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

clean:
	@rm -f $(TARGET)
