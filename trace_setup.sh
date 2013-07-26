#!/bin/bash

FILTER=${FILTER:-tracepoints.txt}
TRACER=${TRACER:-function_graph}
TRACING=${TRACING:-/sys/kernel/debug/tracing}
OPTIONS=${OPTIONS:-print-parent sleep-time graph-time funcgraph-duration funcgraph-overhead funcgraph-cpu funcgraph-abstime funcgraph-proc}

echo "Setup tracing options..."
echo $TRACER > $TRACING/current_tracer
for o in $OPTIONS; do
  echo $o > $TRACING/trace_options
done

echo "Reset old tracing filters..."
echo > $TRACING/set_ftrace_filter

echo "Setup new tracing filters..."
for f in $(grep -v -e '^#' $FILTER); do
  echo $f >> $TRACING/set_ftrace_filter || \
	echo "Failed to setup tracing @ $f"
done

