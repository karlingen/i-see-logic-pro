#!/bin/sh
# Starts Logic Pro with the light theme. Optional arguments are projects to open.
# LP_GAMMA tunes the gray curve (0.5 to 1.5, a lower value is brighter).
# LP_SURFACE_MAX sets the lightest gray (0.65 to 1). Each one overrides the launcher app setting.
dir="$(cd "$(dirname "$0")" && pwd)"

if pgrep -x 'Logic Pro' > /dev/null; then
   echo 'Quit Logic Pro first. The theme loads only at launch.' >&2
   exit 1
fi
if [ ! -f "$dir/light-theme.dylib" ] || [ "$dir/light-theme.m" -nt "$dir/light-theme.dylib" ]; then
   "$dir/build.sh" || exit 1
fi
# The variables pass only when set, so that the launcher app settings apply otherwise.
exec open -n --env DYLD_INSERT_LIBRARIES="$dir/light-theme.dylib" ${LP_GAMMA:+--env "LP_GAMMA=$LP_GAMMA"} ${LP_SURFACE_MAX:+--env "LP_SURFACE_MAX=$LP_SURFACE_MAX"} -a '/Applications/Logic Pro.app' "$@"
