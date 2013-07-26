#!/bin/bash

TRACING=${TRACING:-/sys/kernel/debug/tracing}
FILEDUMP=${1:-trace.dump}

echo "Tracing dumping into [$FILEDUMP]..."
cat $TRACING/trace > $FILEDUMP

