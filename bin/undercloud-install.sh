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
git clone https://github.com/stackforge/tripleo-heat-templates.git
pushd tripleo-heat-templates
git checkout 5e069fece4f9127265ef2e5d0a6df78a1bcdb145
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
# Same for neutron
sudo /opt/stack/venvs/neutron/bin/pip install -U babel

# sudo run from nova rootwrap complains about no tty
sudo sed -i "s/Defaults    requiretty/# Defaults    requiretty/" /etc/sudoers

# the current user needs to always connect to the system's libvirt instance
# when virsh is run
if [ ! -e /etc/profile.d/virsh.sh ]; then
    sudo su -c "cat >> /etc/profile.d/virsh.sh <<EOF

# Connect to system's libvirt instance
export LIBVIRT_DEFAULT_URI=qemu:///system

EOF
"
fi

# rabbitmq-server does not start with selinux enforcing.
sudo setenforce 0
sudo sed -i "s/SELINUX=enforcing/SELINUX=permissive/" /etc/selinux/config

# Overcloud heat template
sudo make -C /opt/stack/tripleo-heat-templates overcloud.yaml

# Download Fedora cloud image.
mkdir -p /opt/stack/images
pushd /opt/stack/images
curl -L -O http://mirror.cogentco.com/pub/linux/fedora/linux/releases/19/Images/x86_64/Fedora-x86_64-19-20130627-sda.qcow2
popd
