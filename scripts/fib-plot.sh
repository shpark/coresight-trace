#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

SCRIPT_DIR="$(cd $(dirname "${BASH_SOURCE[0]}"); pwd)"

OUTPUT=$1
mkdir -p ${OUTPUT}/out

ENVS="native tracing-disable tracing-enable"
SIZES="0x1000 0x10000 0x100000 0x1000000"

for env in $ENVS; do
  for size in $SIZES; do
    grep -h elaps ${OUTPUT}/$env-$size-[1-9].dat | sed "s/elapsed.*//" \
      | awk '{print $3}' \
      | awk -F: '{msecs=$2*1000; msecs+=$1*60*1000; printf "%.3f\n", msecs }' \
      | dbcoldefine latency | dbcolstats -f "%.1f" latency | dbcol mean stddev \
      > ${OUTPUT}/$env-$size-latency.dat
  done
done

SIZE_XTICS="('0x1000' 0, '0x10000' 2, '0x100000' 4, '0x1000000' 6)"

BOX_PAT_NATIVE='fill patter 0 lt 1 lc rgb "green"'
BOX_PAT_DISABLE='fill patter 1 lt 1 lc rgb "blue"'
BOX_PAT_ENABLE='fill patter 2 lt 1 lc rgb "red"'

gnuplot << EndGNUPLOT
set terminal postscript esp lw 3 "Helvetica" 24
set output "${OUTPUT}/out/fib-latency.esp"
set pointsize 2
set xzeroaxis
set grid

set boxwidth 0.25
set style fill pattern
unset key
set size 1.0,0.7
set key top left Left reverse

set xlabel "fib num size"
set xtics font ", 14"
set xtics ${SIZE_XTICS}
set xtics nomirror
set xrange [-1:7]
set ylabel "Latency (msec)"
set yrange [0:10000]
set logscale y 10

plot \
  '${OUTPUT}/native-0x1000-latency.dat' usi (0-0.5):(\$1):(\$2) w boxerrorbar $BOX_PAT_NATIVE title "native", \
  '${OUTPUT}/tracing-disable-0x1000-latency.dat' usi (0-0.0):(\$1):(\$2) w boxerrorbar $BOX_PAT_DISABLE title "non-tracing", \
  '${OUTPUT}/tracing-enable-0x1000-latency.dat' usi (0+0.5):(\$1):(\$2) w boxerrorbar $BOX_PAT_ENABLE title "tracing", \
  '${OUTPUT}/native-0x10000-latency.dat' usi (2-0.5):(\$1):(\$2) w boxerrorbar $BOX_PAT_NATIVE notitle, \
  '${OUTPUT}/tracing-disable-0x10000-latency.dat' usi (2-0.0):(\$1):(\$2) w boxerrorbar $BOX_PAT_DISABLE notitle, \
  '${OUTPUT}/tracing-enable-0x10000-latency.dat' usi (2+0.5):(\$1):(\$2) w boxerrorbar $BOX_PAT_ENABLE notitle, \
  '${OUTPUT}/native-0x100000-latency.dat' usi (4-0.5):(\$1):(\$2) w boxerrorbar $BOX_PAT_NATIVE notitle, \
  '${OUTPUT}/tracing-disable-0x100000-latency.dat' usi (4-0.0):(\$1):(\$2) w boxerrorbar $BOX_PAT_DISABLE notitle, \
  '${OUTPUT}/tracing-enable-0x100000-latency.dat' usi (4+0.5):(\$1):(\$2) w boxerrorbar $BOX_PAT_ENABLE notitle, \
  '${OUTPUT}/native-0x1000000-latency.dat' usi (6-0.5):(\$1):(\$2) w boxerrorbar $BOX_PAT_NATIVE notitle, \
  '${OUTPUT}/tracing-disable-0x1000000-latency.dat' usi (6-0.0):(\$1):(\$2) w boxerrorbar $BOX_PAT_DISABLE notitle, \
  '${OUTPUT}/tracing-enable-0x1000000-latency.dat' usi (6+0.5):(\$1):(\$2) w boxerrorbar $BOX_PAT_ENABLE notitle

set terminal png lw 3 14 crop
set key font ", 14"
set xtics nomirror
set output "${OUTPUT}/out/fib-latency.png"
replot

set terminal dumb
unset output
replot

quit
EndGNUPLOT
