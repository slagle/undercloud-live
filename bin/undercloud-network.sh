#!/bin/bash

set -eux

source /opt/stack/undercloud-live/bin/undercloud-common.sh

# This script needs to be rerun if you reboot the undercloud.

wait_for 12 10 ls /var/run/libvirt/libvirt-sock

PUBLIC_INTERFACE=${PUBLIC_INTERFACE:-ucl0}

sudo sed -i "s/bridge name='brbm'/bridge name='br-ctlplane'/" /opt/stack/tripleo-incubator/templates/brbm.xml
/opt/stack/tripleo-incubator/scripts/setup-network

sudo ip link add $PUBLIC_INTERFACE type dummy
# init-neutron-ovs is also executed by os-refresh-config, but it's done here
# because we can stop and make sure it's done the right thing easier to debug,
# etc.
sudo init-neutron-ovs

# TODO: This is bad, but there's a bug somewhere in the firewall configuration
# that causes the overcloud to not be able to get it's initial pxe boot files.
# Disabling the firewall for now just for testing.
sudo systemctl stop firewalld

# Restart dnsmasq service.  This is needed b/c br-ctlplane was assigned an IP.
sudo systemctl restart nova-bm-dnsmasq
