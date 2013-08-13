#!/bin/bash

set -eux


# Migrate over to the latest setuptools
sudo pip install -U distribute
sudo pip install -U setuptools

# For some reason, pbr is not getting installed correctly.
# It is listed as setup_requires for diskimage-builder, and 
# pip thinks it's installed from then on out, even though it is not.
sudo pip install pbr

sudo yum install -y python-lxml libvirt-python libvirt qemu-img qemu-kvm git python-pip openssl-devel python-devel gcc audit python-virtualenv openvswitch python-yaml

sudo mkdir -m 777 -p /opt/stack
pushd /opt/stack

git clone https://github.com/slagle/python-dib-elements.git
git clone https://github.com/slagle/undercloud-live.git
git clone https://github.com/openstack/tripleo-incubator.git
pushd tripleo-incubator
git checkout 41b291844f8aed34fdbc87e959358fad407df36e
popd
git clone https://github.com/stackforge/diskimage-builder.git
pushd diskimage-builder
git checkout 97bc5d7853ebd41d878c8e8c30ee87ccaff1189a
popd
git clone https://github.com/stackforge/tripleo-image-elements.git
pushd tripleo-image-elements
git checkout 988bed89673235fb82fc94d5fcb11080ee4c878e
popd

sudo pip install -e python-dib-elements
sudo pip install -e diskimage-builder

dib-elements -p diskimage-builder/elements/ tripleo-image-elements/elements/ \
    -e fedora \
    -k pre-install
dib-elements -p diskimage-builder/elements/ tripleo-image-elements/elements/ \
    -e source-repositories boot-stack \
    -k extra-data
# selinux-permissive is included b/c rabbitmq-server does not start with
# selinux enforcing.
dib-elements -p diskimage-builder/elements/ tripleo-image-elements/elements/ \
                undercloud-live/elements \
    -e boot-stack nova-baremetal heat-localip heat-cfntools stackuser \
       undercloud-live-config selinux-permissive \
    -k install

popd

# Keystone is not installing babel for some reason
sudo /opt/stack/venvs/keystone/bin/pip install -U babel

# Download Fedora cloud image.
mkdir -p /opt/stack/images
pushd /opt/stack/images
curl -L -O http://mirror.cogentco.com/pub/linux/fedora/linux/releases/19/Images/x86_64/Fedora-x86_64-19-20130627-sda.qcow2
popd
