#!/bin/bash

if [ $# -lt 1 ]; then
  echo "Usage: $1 <ms_to_trace>"
  exit -1
fi

MS=${1:-100}
SLEEP=$(echo "scale=3; $MS/1000;" | bc)

TRACING=${TRACING:-/sys/kernel/debug/tracing}

echo 0 > $TRACING/tracing_on
echo nop > $TRACING/current_tracer
echo 1 > $TTRACING/function_profile_enabledo

echo "Profiling scheduler function for $SLEEP [s]..."
echo 1 > $TRACING/tracing_on
sleep $SLEEP
echo 0 > $TRACING/tracing_on

for f in $TRACING/trace_stat/function*; do
  FILENAME=`basename $f`
  cp $f dump_sched_profile_${MS}_${FILENAME}.dat
done

