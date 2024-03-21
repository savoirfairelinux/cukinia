#!/bin/sh

# Get the current second number
second=$(date +%S)

# Check if the second number is even
if [ $((second % 2)) -eq 0 ]; then
    exit 0  # Success
else
    exit 1  # Failure
fi
