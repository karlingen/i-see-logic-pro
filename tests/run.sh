#!/bin/sh
# Builds and runs the theme tests and the app tests. They do not need Logic Pro.
cd "$(dirname "$0")" || exit 1
work=$(mktemp -d) || exit 1
clang -arch arm64 -fobjc-arc -Wno-deprecated-declarations -Wno-undeclared-selector -Wno-unused-function \
   -framework AppKit -o "$work/theme-tests" theme-tests.m || exit 1
"$work/theme-tests" || status=1
# The app has its own checks, which do not need a window or Logic Pro.
swiftc -O ../app/UpdateCheck.swift app-tests.swift -o "$work/app-tests" || status=1
"$work/app-tests" || status=1
rm -r "$work"
exit ${status:-0}
