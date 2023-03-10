#!/bin/bash

# DEBUG mod
#bash -x quickyad 2>&1 | tee output.log

# YAD gui script for excellent quickemu
#TODO Download Icons
#TODO Add homepages to right click

echo "Running..."
# dependencies checks
if ! command -v yad >/dev/null 2>&1; then
    echo "You are missing yad..." >&2
    exit 1
fi
if ! command -v quickemu >/dev/null 2>&1; then
    echo "You are missing quickemu..." >&2
    exit 1
fi
