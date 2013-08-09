#!/bin/bash

set -eux

# the current user needs to always connect to the system's libvirt instance
# when virsh is run
cat >> ~/.bashrc <<EOF

# Connect to system's libvirt instance
alias virsh='/usr/bin/virsh -c qemu:///system'

EOF

sudo mkdir -m 777 -p /opt/stack
pushd /opt/stack

git clone https://github.com/slagle/python-dib-elements.git
git clone https://github.com/slagle/undercloud-live.git
git clone https://github.com/stackforge/diskimage-builder.git
git clone https://github.com/openstack/tripleo-incubator.git
git clone https://github.com/stackforge/tripleo-image-elements.git

sudo pip install -e python-dib-elements
sudo pip install -e diskimage-builder

/opt/stack/undercloud-live/bin/install-dependencies
/opt/stack/tripleo-incubator/scripts/setup-network

dib-elements -p diskimage-builder/elements/ tripleo-image-elements/elements/ \
    -e fedora \
    -k pre-install
dib-elements -p diskimage-builder/elements/ tripleo-image-elements/elements/ \
    -e source-repositories boot-stack \
    -k extra-data
dib-elements -p diskimage-builder/elements/ tripleo-image-elements/elements/ \
    -e boot-stack nova-baremetal heat-localip heat-cfntools stackuser \
       undercloude-live-config \
    -k install

popd

# Download Fedora cloud image.
mkdir -p /opt/stack/images
pushd /opt/stack/images
curl -L -O http://download.fedoraproject.org/pub/fedora/linux/releases/19/Images/x86_64/Fedora-x86_64-19-20130627-sda.qcow2
popd
