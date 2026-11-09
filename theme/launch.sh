#!/bin/sh
# Starts Logic Pro with the light theme. Optional arguments are projects to open.
# LP_GAMMA tunes gray lightness (default 0.75, a lower value is brighter).
dir="$(cd "$(dirname "$0")" && pwd)"

if pgrep -x 'Logic Pro' > /dev/null; then
   echo 'Quit Logic Pro first. The theme loads only at launch.' >&2
   exit 1
fi
if [ ! -f "$dir/light-theme.dylib" ] || [ "$dir/light-theme.m" -nt "$dir/light-theme.dylib" ]; then
   "$dir/build.sh" || exit 1
fi
exec open -n --env DYLD_INSERT_LIBRARIES="$dir/light-theme.dylib" --env LP_GAMMA="${LP_GAMMA:-0.75}" -a '/Applications/Logic Pro.app' "$@"
