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
git clone https://github.com/stackforge/diskimage-builder.git
git clone https://github.com/openstack/tripleo-incubator.git
git clone https://github.com/stackforge/tripleo-image-elements.git

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
sudo source /opt/stack/venvs/keystone/bin/activate
pip install -U babel
deactivate

# Download Fedora cloud image.
mkdir -p /opt/stack/images
pushd /opt/stack/images
curl -L -O http://download.fedoraproject.org/pub/fedora/linux/releases/19/Images/x86_64/Fedora-x86_64-19-20130627-sda.qcow2
popd
