#!/bin/bash

# Eventually, this script may run diskimage-builder commands, for now it just
# downloads images from a preconfigured location.

set -eux

IMAGES_DIR=/opt/stack/images
CONTROL_IMG=$IMAGES_DIR/overcloud-control.qcow2
COMPUTE_IMG=$IMAGES_DIR/overcloud-compute.qcow2
BM_KERNEL=$IMAGES_DIR/deploy-ramdisk.kernel
BM_INITRAMFS=$IMAGES_DIR/deploy-ramdisk.initramfs
ELEMENTS_PATH=/opt/stack/tripleo-image-elements/elements

export ELEMENTS_PATH

mkdir -p $IMAGES_DIR
pushd $IMAGES_DIR

# curl -L -O $DEPLOY_KERNEL_URL
# curl -L -O $DEPLOY_INITRAMFS_URL
# curl -L -O $OVERCLOUD_COMPUTE_URL
# curl -L -O $OVERCLOUD_CONTROL_URL

# This is a fast mirror, for me anyway :-).
# curl -L -O http://mirror.cogentco.com/pub/linux/fedora/linux/releases/19/Images/x86_64/Fedora-x86_64-19-20130627-sda.qcow2

popd

if [ ! -f $BM_KERNEL ]; then
    /opt/stack/diskimage-builder/bin/disk-image-create \
        -a amd64 \
        -o $IMAGES_DIR/deploy-ramdisk \
        fedora deploy
fi

if [ ! -f $CONTROL_IMG ]; then
    /opt/stack/diskimage-builder/bin/disk-image-create \
        -a amd64 \
        -o $IMAGES_DIR/overcloud-control \
        fedora boot-stack cinder heat-localip \
        heat-cfntools neutron-network-node stackuser
fi

if [ ! -f $COMPUTE_IMG ]; then
    /opt/stack/diskimage-builder/bin/disk-image-create \
        -a amd64 \
        -o $IMAGES_DIR/overcloud-control \
        fedora overcloud-compute nova-compute nova-kvm \
        neutron-openvswitch-agent heat-localip heat-cfntools stackuser
fi

# MACS must be set for setup-baremetal to work
export MACS=$(bm_poseur get-macs)
# $TRIPLEO_ROOT is not true to the tripleo sense, but it's where
# setup-baremetal look for the deploy kernel and ramfs.
TRIPLEO_ROOT=/opt/stack/images /opt/stack/tripleo-incubator/scripts/setup-baremetal 1 1024 10 undercloud
/opt/stack/tripleo-incubator/scripts/load-image $COMPUTE_IMG
/opt/stack/tripleo-incubator/scripts/load-image $CONTROL_IMG
