#!/bin/bash

# Eventually, this script may run diskimage-builder commands, for now it just
# downloads images from a preconfigured location.

set -eux

source $HOME/undercloudrc

IMAGES_DIR=/opt/stack/images
CONTROL_IMG=$IMAGES_DIR/overcloud-control.qcow2
COMPUTE_IMG=$IMAGES_DIR/overcloud-compute.qcow2
BM_KERNEL=$IMAGES_DIR/deploy-ramdisk.kernel
BM_INITRAMFS=$IMAGES_DIR/deploy-ramdisk.initramfs
ELEMENTS_PATH=/opt/stack/tripleo-image-elements/elements

export ELEMENTS_PATH

mkdir -p $IMAGES_DIR

if [ ! -f $BM_KERNEL ]; then
    /opt/stack/diskimage-builder/bin/ramdisk-image-create \
        -a amd64 \
        --offline \
        -o $IMAGES_DIR/deploy-ramdisk \
        fedora deploy pip-cache
fi

if [ ! -f $CONTROL_IMG ]; then
    /opt/stack/diskimage-builder/bin/disk-image-create \
        -a amd64 \
        --offline \
        -o $IMAGES_DIR/overcloud-control \
        fedora boot-stack \
        heat-cfntools neutron-network-node stackuser pip-cache
fi

if [ ! -f $COMPUTE_IMG ]; then
    /opt/stack/diskimage-builder/bin/disk-image-create \
        -a amd64 \
        --offline \
        -o $IMAGES_DIR/overcloud-compute \
        fedora nova-compute nova-kvm \
        neutron-openvswitch-agent heat-cfntools stackuser pip-cache
fi

/opt/stack/undercloud-live/bin/baremetal.sh

/opt/stack/tripleo-incubator/scripts/load-image $COMPUTE_IMG
/opt/stack/tripleo-incubator/scripts/load-image $CONTROL_IMG
