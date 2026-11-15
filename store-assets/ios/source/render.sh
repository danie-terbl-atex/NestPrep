#!/bin/zsh
# render.sh <html?query> <out.png> <w> <h>
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 --allow-file-access-from-files --virtual-time-budget=4000 --window-size=$3,$4 --screenshot="$2" "file:///private/tmp/claude-501/-Users-danielterblanche-Documents-NullState-NestPrep/7dac42d0-842b-4e5e-bd97-e6304e982ce6/scratchpad/build/$1" >/dev/null 2>&1
