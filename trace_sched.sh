#!/bin/bash

if [ $# -lt 1 ]; then
  echo "Usage: $1 <ms_to_trace>"
  exit -1
fi

MS=${1:-100}
SLEEP=$(echo "scale=3; $MS/1000;" | bc)

TRACING=${TRACING:-/sys/kernel/debug/tracing}
TRACER=${TRACER:-function_graph}

echo 0 > $TRACING/tracing_on
echo nop > $TRACING/current_tracer
echo $TRACER > $TRACING/current_tracer

echo "Tracing scheduler for $SLEEP [s]..."
echo 1 > $TRACING/tracing_on
sleep $SLEEP
echo 0 > $TRACING/tracing_on

BASENAME="$(date +%Y%m%d_%H%M)_trace_sched"
echo "Trace dumps ${BASENAME}..."
cat $TRACING/trace > ${BASENAME}_${MS}.trace
for f in $TRACING/per_cpu/cpu*; do
  CPUTRACE=`basename $f`
  cat $f/trace > ${BASENAME}_${MS}_${CPUTRACE}.trace
done

