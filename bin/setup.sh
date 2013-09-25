#!/bin/bash

set -eux

source /opt/stack/undercloud-live/bin/common.sh

# The commands in this script require a running, configured cloud.

if [ -f /opt/stack/undercloud-live/.setup ]; then
    exit
fi

source $HOME/undercloudrc

# Ensure keystone is up before continuing on.
# Waits for up to 2 minutes.
wait_for 12 10 sudo systemctl status keystone

# Because keystone just still isn't up yet...
sleep 20

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
sudo -i /opt/stack/tripleo-incubator/scripts/create-nodes 1 2048 10 2

sudo touch /opt/stack/undercloud-live/.setup
