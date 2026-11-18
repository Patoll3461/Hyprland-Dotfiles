#!/usr/bin/env bash

file="$1"

read w h < <(identify -format "%w %h" "$file")
echo "Resolution: ${w}x${h}"