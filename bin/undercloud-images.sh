#!/bin/bash

# Eventually, this script may run diskimage-builder commands, for now it just
# downloads images from a preconfigured location.

set -eux

mkdir -p /opt/stack/images
pushd /opt/stack/images

curl -L -O $DEPLOY_KERNEL_URL
curl -L -O $DEPLOY_INITRAMFS_URL
curl -L -O $OVERCLOUD_COMPUTE_URL
curl -L -O $OVERCLOUD_CONTROL_URL

# This is a fast mirror, for me anyway :-).
curl -L -O http://mirror.cogentco.com/pub/linux/fedora/linux/releases/19/Images/x86_64/Fedora-x86_64-19-20130627-sda.qcow2

popd

# MACS must be set for setup-baremetal to work
export MACS=$(bm_poseur get-macs)
# $TRIPLEO_ROOT is not true to the tripleo sense, but it's where
# setup-baremetal look for the deploy kernel and ramfs.
TRIPLEO_ROOT=/opt/stack/images /opt/stack/tripleo-incubator/scripts/setup-baremetal 1 1024 10 undercloud
/opt/stack/tripleo-incubator/scripts/load-image /opt/stack/images/overcloud-compute.qcow2
/opt/stack/tripleo-incubator/scripts/load-image /opt/stack/images/overcloud-control.qcow2
