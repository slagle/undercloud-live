#!/bin/bash

set -eux

source /opt/stack/undercloud-live/bin/undercloud-common.sh

# This script needs to be rerun if you reboot the undercloud.

wait_for 12 10 ls /var/run/libvirt/libvirt-sock

# need to exec to pick up the new group
if ! id | grep libvirtd; then
    exec sudo su -l $USER $0
fi

PUBLIC_INTERFACE=${PUBLIC_INTERFACE:-ucl0}

sudo sed -i "s/bridge name='brbm'/bridge name='br-ctlplane'/" /opt/stack/tripleo-incubator/templates/brbm.xml
/opt/stack/tripleo-incubator/scripts/setup-network

sudo ip link add $PUBLIC_INTERFACE type dummy

# Restart dnsmasq service.  This is needed b/c br-ctlplane was assigned an IP.
sudo systemctl restart nova-bm-dnsmasq
