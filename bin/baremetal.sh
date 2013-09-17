#!/bin/bash

# Script to perform baremetal setup.
# This can be run multiple times, but you must first delete your existing
# baremetal nodes in nova with 'nova baremetal-node-delete'.

set -eux

# MACS must be set for setup-baremetal to work
export MACS=$(bm_poseur get-macs)
# $TRIPLEO_ROOT is not true to the tripleo sense, but it's where
# setup-baremetal look for the deploy kernel and ramfs.
TRIPLEO_ROOT=/opt/stack/images /opt/stack/tripleo-incubator/scripts/setup-baremetal 1 1024 10 all

# Workaround for https://bugs.launchpad.net/nova/+bug/1213967
nova flavor-key baremetal unset cpu_arch
