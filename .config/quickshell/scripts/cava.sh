#!/bin/bash
cava &

while read line; do
    echo "$line"
done < /tmp/cava.fifo

killall cava
