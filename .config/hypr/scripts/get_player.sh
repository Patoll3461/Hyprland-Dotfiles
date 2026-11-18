#!/bin/bash

output=$(playerctl metadata --format '{{artist}} - {{title}}' 2>/dev/null)
status=$?

if [ $status -ne 0 ] || [ -z "$output" ]; then
    echo "Nothing playing"
else
    echo "$output" | sed '/^$/d'
fi