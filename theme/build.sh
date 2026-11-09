#!/bin/sh
# Builds light-theme.dylib beside this script. Run it again after a Logic Pro update.
cd "$(dirname "$0")" || exit 1
python3 -I gen-colors.py logic-colors.h || exit 1
clang -arch arm64 -dynamiclib -fobjc-arc -Wno-deprecated-declarations -Wno-undeclared-selector -framework AppKit -o light-theme.dylib light-theme.m && codesign -s - -f light-theme.dylib
