#!/bin/bash

set -eux

# Stop all services
pushd /lib/systemd/system
for s in nova* neutron* glance* keystone* heat* mysql* os-collect-config*; do sudo systemctl stop $s; done
popd

# Delete services
rm -rf /lib/systemd/system/nova*
rm -rf /lib/systemd/system/neutron*
rm -rf /lib/systemd/system/glance*
rm -rf /lib/systemd/system/keystone*
rm -rf /lib/systemd/system/heat*
rm -rf /lib/systemd/system/os-collect-config*

# Clean up directories
rm -rf /opt/stack
rm -rf /var/lib/glance
rm -rf /var/lib/nova
rm -rf /var/lib/heat
rm -rf /var/lib/heat-cfntools
rm -rf /var/lib/neutron

# Clean up libvirt
for NAME in $(sudo virsh list --name --all | grep "^\(seed\|bootstrap\|baremetal_.*\)$"); do
    sudo virsh destroy $NAME
    sudo virsh undefine --remove-all-storage $NAME
done

for NAME in $(virsh vol-list default | grep /var/ | awk '{print $1}' | grep "^\(seed\|bootstrap\|baremetal-\)" ); do
    sudo virsh vol-delete --pool default $NAME
done
