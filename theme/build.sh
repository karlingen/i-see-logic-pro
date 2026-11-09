#!/bin/sh
# Builds light-theme.dylib beside this script.
cd "$(dirname "$0")" || exit 1
clang -arch arm64 -dynamiclib -fobjc-arc -Wno-deprecated-declarations -Wno-undeclared-selector -framework AppKit -o light-theme.dylib light-theme.m && codesign -s - -f light-theme.dylib
