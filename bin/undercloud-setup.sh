#!/bin/bash

set -eux

# The commands in this script require a running, configured cloud.

if [ -f /opt/stack/undercloud-live/.undercloud-setup ]; then
    exit
fi

source $HOME/undercloudrc

# Make sure we have the latest $PATH set.
source /etc/profile.d/tripleo-incubator-scripts.sh

export UNDERCLOUD_IP=192.0.2.1
SERVICE_TOKEN=unset /opt/stack/tripleo-incubator/scripts/setup-endpoints $UNDERCLOUD_IP

# Adds default ssh key to nova
/opt/stack/tripleo-incubator/scripts/user-config

/opt/stack/tripleo-incubator/scripts/setup-neutron 192.0.2.5 192.0.2.24 192.0.2.0/24 $UNDERCLOUD_IP ctlplane

cat /opt/stack/boot-stack/virtual-power-key.pub >> ~/.ssh/authorized_keys

# Baremetal setup
/opt/stack/tripleo-incubator/scripts/create-nodes 1 1024 10 2

touch /opt/stack/undercloud-live/.undercloud-setup
