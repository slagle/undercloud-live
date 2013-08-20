#!/bin/bash

set -eux

# The commands in this script require a running, configured cloud.

source $HOME/undercloudrc

export UNDERCLOUD_IP=192.0.2.1
/opt/stack/tripleo-incubator/scripts/setup-neutron 192.0.2.5 192.0.2.24 192.0.2.0/24 $UNDERCLOUD_IP ctlplane

# Adds default ssh key to nova
/opt/stack/tripleo-incubator/scripts/user-config

cat /opt/stack/boot-stack/virtual-power-key.pub >> ~/.ssh/authorized_keys

# Baremetal setup
/opt/stack/tripleo-incubator/scripts/create-nodes 1 1024 10 2
