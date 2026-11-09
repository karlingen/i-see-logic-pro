#!/bin/sh
# Starts Logic Pro with the light theme. Optional arguments are projects to open.
# LP_GAMMA tunes the gray curve (default 0.75, a lower value is brighter).
# LP_SURFACE_MAX sets the lightest gray (default 1, minimum 0.65).
dir="$(cd "$(dirname "$0")" && pwd)"

if pgrep -x 'Logic Pro' > /dev/null; then
   echo 'Quit Logic Pro first. The theme loads only at launch.' >&2
   exit 1
fi
if [ ! -f "$dir/light-theme.dylib" ] || [ "$dir/light-theme.m" -nt "$dir/light-theme.dylib" ]; then
   "$dir/build.sh" || exit 1
fi
exec open -n --env DYLD_INSERT_LIBRARIES="$dir/light-theme.dylib" --env LP_GAMMA="${LP_GAMMA:-0.75}" --env LP_SURFACE_MAX="${LP_SURFACE_MAX:-1}" -a '/Applications/Logic Pro.app' "$@"
