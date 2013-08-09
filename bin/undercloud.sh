#!/bin/bash

set -eux

git clone https://github.com/slagle/python-dib-elements.git
git clone https://github.com/stackforge/diskimage-builder.git
git clone https://github.com/openstack/tripleo-incubator.git
git clone https://github.com/stackforge/tripleo-image-elements.git

sudo yum -y install python-pip
sudo pip install -e python-dib-elements
sudo pip install -e diskimage-builder

dib-elements -p diskimage-builder/elements/ tripleo-image-elements/elements/ \
    -e fedora \
    -k pre-install
dib-elements -p diskimage-builder/elements/ tripleo-image-elements/elements/ \
    -e source-repositories boot-stack \
    -k extra-data
dib-elements -p diskimage-builder/elements/ tripleo-image-elements/elements/ \
    -e boot-stack nova-baremetal heat-localip heat-cfntools stackuser \
    -k install

