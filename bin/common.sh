#!/bin/bash

set -eux

# wait_for method borrowed from:
# https://github.com/qwefi/toci/blob/master/toci_functions.sh
wait_for(){
    LOOPS=$1
    SLEEPTIME=$2
    shift ; shift
    i=0
    while [ $i -lt $LOOPS ] ; do
        i=$((i + 1))
        eval "$@" && return 0 || true
        sleep $SLEEPTIME
    done
    return 1
}


