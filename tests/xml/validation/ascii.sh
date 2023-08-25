#!/bin/sh

for i in $(seq 0 255); do
    printf "\\$(printf '%03o' $i)"
    >&2 printf "\\$(printf '%03o' $i)"
done
