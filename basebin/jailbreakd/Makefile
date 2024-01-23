TARGET = jailbreakd

CC = clang++

CFLAGS = -Wall -std=c++11 -framework Foundation -framework CoreServices -framework Security -framework IOKit -framework UIKit -I./_shared -I./ -I./utils -isysroot $(shell xcrun --sdk iphoneos --show-sdk-path) -arch arm64 -miphoneos-version-min=15.4 -fobjc-arc -Wno-nullability-completeness-on-arrays -O3
LDFLAGS = -lbsm

CFLAGS += -DVERSION_COMMIT_COUNT='" "'
CFLAGS += -DVERSION_COMMIT_SHA='" "'

sign: $(TARGET)
	codesign -f -s - --timestamp=none --all-architectures --entitlements ./entitlements.plist --deep $<
	mv $< ../../binaries
	rm ../../binaries/jb.tc || true
	trustcache create -v $(TRUSTCACHEVERSION) ../../binaries/jb.tc ../../binaries
	cd ../../binaries && tar -cvf ../binaries.tar ./
$(TARGET): $(wildcard *.mm ./utils/*.mm ./kernel/*.mm)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

clean:
	@rm -f $(TARGET)
