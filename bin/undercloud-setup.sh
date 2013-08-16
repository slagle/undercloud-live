#!/bin/bash

set -eux

# The commands in this script require a running, configured cloud.

source $HOME/undercloudrc

export UNDERCLOUD_IP=192.0.2.1
/opt/stack/tripleo-incubator/scripts/setup-neutron 192.0.2.5 192.0.2.24 192.0.2.0/24 $UNDERCLOUD_IP ctlplane

# Adds default ssh key to nova
/opt/stack/tripleo-incubator/scripts/user-config

# Baremetal setup
/opt/stack/tripleo-incubator/scripts/create-nodes 1 1024 10 3
# MACS must be set for setup-baremetal to work
export MACS=$(bm_poseur get-macs)
sudo sed -i "s/ubuntu/undercloud-live/g" /opt/stack/tripleo-incubator/scripts/register-nodes
# $TRIPLEO_ROOT is not true to the tripleo sense, but it's where
# setup-baremetal look for the deploy kernel and ramfs.
TRIPLEO_ROOT=/opt/stack/images /opt/stack/tripleo-incubator/scripts/setup-baremetal 1 1024 10 undercloud
cat /opt/stack/boot-stack/virtual-power-key.pub >> ~/.ssh/authorized_keys
/opt/stack/tripleo-incubator/scripts/load-image /opt/stack/images/overcloud-compute.qcow2
/opt/stack/tripleo-incubator/scripts/load-image /opt/stack/images/overcloud-control.qcow2
