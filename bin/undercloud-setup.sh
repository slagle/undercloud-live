#!/bin/bash

set -eux

# The commands in this script require a running, configured cloud.

# If /opt/stack/images is not in /etc/fstab, then we must have installed to
# disk and therefore, this script has already run.
if [ ! `grep /opt/stack/images /etc/fstab` ]; then
    sudo touch /opt/stack/undercloud-live/.undercloud-setup
fi

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
# Doing this as root b/c when this script is called from systemd, the access
# to the libvirtd socket is restricted.
sudo -i /opt/stack/tripleo-incubator/scripts/create-nodes 1 1024 10 2

sudo touch /opt/stack/undercloud-live/.undercloud-setup
