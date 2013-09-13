#!/bin/bash

set -eux

if [ -f /opt/stack/undercloud-live/.install ]; then
    echo install.sh has already run, exiting.
    exit
fi

# Make sure pip is installed
sudo yum install -y python-pip

# busybox is a requirement of ramdisk-image-create from diskimage-builder
sudo yum install -y busybox

# The packaged version of pbr that gets installed is 
# python-pbr-0.5.19-2.fc19.noarch
# However, the unpackaged os-*-config expect pbr>=0.5.21, so we need to still
# use pip to update pbr for now.
sudo pip install -U pbr

# This directory is still required because not all the elements in
# tripleo-puppet-elements has been updated to use packages, specifically
# os-*-config still use git clones and expect this directory to be created.
sudo mkdir -m 777 -p /opt/stack
pushd /opt/stack

git clone https://github.com/slagle/python-dib-elements.git
git clone https://github.com/slagle/undercloud-live.git
pushd undercloud-live
git checkout package
popd

git clone https://github.com/slagle/tripleo-incubator.git
pushd tripleo-incubator
# we have to continue to use a branch here for x86_64 to work, and our other
# undercloud changes
git checkout undercloud-live
popd

git clone https://github.com/openstack/diskimage-builder.git
pushd diskimage-builder
git checkout 9211a7fecbadc13e8254085133df1e3b53f150d8
popd

git clone https://github.com/agroup/tripleo-puppet-elements
pushd tripleo-puppet-elements
git checkout puppet_dev
popd

git clone https://github.com/openstack/tripleo-heat-templates.git
pushd tripleo-heat-templates
git checkout c34e381a46ea6808256abb3300760cb422192869
popd

git clone https://github.com/tripleo/bm_poseur
pushd bm_poseur
git checkout 13c65747f50bda0cec4e90cc37aed6679a70da95
popd

sudo pip install -e python-dib-elements
sudo pip install -e diskimage-builder

# Add a symlink for bm_poseur as it has no setup.py
sudo ln -s /opt/stack/bm_poseur/bm_poseur /usr/local/bin/bm_poseur

# Add scripts directory from tripleo-incubator and diskimage-builder to the
# path.
# These scripts can't just be symlinked into a bin directory because they do
# directory manipulation that assumes they're in a known location.
if [ ! -e /etc/profile.d/tripleo-incubator-scripts.sh ]; then
    sudo bash -c "echo export PATH='\$PATH':/opt/stack/tripleo-incubator/scripts/ >> /etc/profile.d/tripleo-incubator-scripts.sh"
    sudo bash -c "echo export PATH=/opt/stack/diskimage-builder/bin/:'\$PATH' >> /etc/profile.d/tripleo-incubator-scripts.sh"
fi

# sudo run from nova rootwrap complains about no tty
sudo sed -i "s/Defaults    requiretty/# Defaults    requiretty/" /etc/sudoers
# need to be able to pass in a modified $PATH for sudo for dib-elements to work
sudo sed -i "s/Defaults    secure_path/# Defaults    secure_path/" /etc/sudoers

dib-elements -p diskimage-builder/elements/ tripleo-puppet-elements/elements/ \
    -e fedora openstack-m-repo \
    -k pre-install \
    -i
dib-elements -p diskimage-builder/elements/ tripleo-puppet-elements/elements/ \
    -e source-repositories boot-stack nova-baremetal \
    -k extra-data \
    -i
# rabbitmq-server does not start with selinux enforcing.
# https://bugzilla.redhat.com/show_bug.cgi?id=998682
dib-elements -p diskimage-builder/elements/ tripleo-puppet-elements/elements/ \
                undercloud-live/elements \
    -e boot-stack nova-baremetal stackuser heat-cfntools \
       undercloud-live-config selinux-permissive \
    -k install \
    -i

popd

# the current user needs to always connect to the system's libvirt instance
# when virsh is run
if [ ! -e /etc/profile.d/virsh.sh ]; then
    sudo su -c "cat >> /etc/profile.d/virsh.sh <<EOF

# Connect to system's libvirt instance
export LIBVIRT_DEFAULT_URI=qemu:///system

EOF
"
fi

# Overcloud heat template
sudo make -C /opt/stack/tripleo-heat-templates overcloud.yaml

touch /opt/stack/undercloud-live/.install 
