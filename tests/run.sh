#!/bin/sh
# Builds and runs the theme tests. They do not need Logic Pro.
cd "$(dirname "$0")" || exit 1
work=$(mktemp -d) || exit 1
clang -arch arm64 -fobjc-arc -Wno-deprecated-declarations -Wno-undeclared-selector -Wno-unused-function \
   -framework AppKit -o "$work/theme-tests" theme-tests.m || exit 1
"$work/theme-tests"
status=$?
rm -r "$work"
exit $status
