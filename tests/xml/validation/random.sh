#!/bin/sh

cat /dev/urandom | dd bs=1M count=1
cat /dev/urandom | >&2 dd bs=1M count=1
