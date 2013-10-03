#!/bin/bash

set -eux

source /opt/stack/undercloud-live/bin/common.sh

# This script needs to be rerun if you reboot the undercloud.

wait_for 12 10 ls /var/run/libvirt/libvirt-sock

PUBLIC_INTERFACE=${PUBLIC_INTERFACE:-ucl0}

sudo sed -i "s/bridge name='brbm'/bridge name='br-ctlplane'/" /opt/stack/tripleo-incubator/templates/brbm.xml
/opt/stack/tripleo-incubator/scripts/setup-network

sudo ip link del $PUBLIC_INTERFACE || true
sudo ip link add $PUBLIC_INTERFACE type dummy

sudo init-neutron-ovs
