#!/bin/sh

make
cp ".theos/obj/rootlesshooks.dylib" "../../binaries"
rm ../../binaries/binaries.tc
trustcache create ../../binaries/binaries.tc ../../binaries
find ../.. -type f -name '.*' -delete