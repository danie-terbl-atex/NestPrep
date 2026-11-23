#!/bin/zsh
# render.sh <html?query> <out.png> <w> <h> [scale]
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=${5:-1} --allow-file-access-from-files --virtual-time-budget=4000 --window-size=$3,$4 --screenshot="$2" "file://${0:A:h}/$1" >/dev/null 2>&1
