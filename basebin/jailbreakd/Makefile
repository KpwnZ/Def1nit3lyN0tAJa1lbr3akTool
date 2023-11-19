TARGET = jailbreakd

CC = clang++

CFLAGS = -Wall -std=c++11 -framework Foundation -framework CoreServices -framework Security -framework IOKit -framework UIKit -I./_shared -I./ -I./utils -isysroot $(shell xcrun --sdk iphoneos --show-sdk-path) -arch arm64 -miphoneos-version-min=15.0 -fobjc-arc -Wno-nullability-completeness-on-arrays -O3
LDFLAGS = -lbsm 

CFLAGS += -DVERSION_COMMIT_COUNT='" "'
CFLAGS += -DVERSION_COMMIT_SHA='" "'

sign: $(TARGET)
	@ldid -Sentitlements.plist $<
	mv $< ../../binaries
	trustcache create ../../binaries/jb.tc ../../binaries

$(TARGET): $(wildcard *.mm ./utils/*.mm ./kernel/*.mm)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

clean:
	@rm -f $(TARGET)
