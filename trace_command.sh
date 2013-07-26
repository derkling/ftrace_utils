#!/bin/bash

TRACING=${TRACING:-/sys/kernel/debug/tracing}
TRACER=${FILTER:-function_graph}
FILTER=${FILTER:-tracepoints.txt}

echo "Tracing command [$*]..."
echo $$ > $TRACING/set_ftrace_pid
echo nop > $TRACING/current_tracer
echo $TRACER > $TRACING/current_tracer
exec $*

