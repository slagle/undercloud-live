#!/bin/bash

set -eux

os=redhat


# This is the "fake" interface needed for init-neutron-ovs
PUBLIC_INTERFACE=${PUBLIC_INTERFACE:-ucl0}

# These variables are meant to be overridden if they need to be changed.
# If you're testing on a vm that is running on a host with the default
# 192.168.122.1 network already defined, you will want to set environment
# variables to override these.
NETWORK=${NETWORK:-192.168.122.1}
LIBVIRT_IP_ADDRESS=${LIBVIRT_IP_ADDRESS:-192.168.122.1}
LIBVIRT_NETWORK_RANGE_START=${LIBVIRT_NETWORK_RANGE_START:-192.168.122.2}
LIBVIRT_NETWORK_RANGE_END=${LIBVIRT_NETWORK_RANGE_END:-192.168.122.254}

if [ -e /opt/stack/undercloud-live/.undercloud-configure ]; then
    echo undercloud-configure has already run, exiting.
    exit
fi

# rabbitmq-server does not start with selinux enforcing.
# https://bugzilla.redhat.com/show_bug.cgi?id=998682
sudo setenforce 0

sudo sed -i "s/192.168.122.1/$LIBVIRT_IP_ADDRESS/g" /etc/libvirt/qemu/networks/default.xml
sudo sed -i "s/192.168.122.2/$LIBVIRT_NETWORK_RANGE_START/g" /etc/libvirt/qemu/networks/default.xml
sudo sed -i "s/192.168.122.254/$LIBVIRT_NETWORK_RANGE_END/g" /etc/libvirt/qemu/networks/default.xml

# This libvirtd group modification should be at the top of the script due to
# the exec.  
grep libvirtd /etc/group || sudo groupadd libvirtd
if ! id | grep libvirtd; then
   echo "adding $USER to group libvirtd"
   sudo usermod -a -G libvirtd $USER

   if [ "$os" = "redhat" ]; then
       libvirtd_file=/etc/libvirt/libvirtd.conf
       if ! sudo grep "^unix_sock_group" $libvirtd_file > /dev/null; then
           sudo sed -i 's/^#unix_sock_group.*/unix_sock_group = "libvirtd"/g' $libvirtd_file
           sudo sed -i 's/^#auth_unix_rw.*/auth_unix_rw = "none"/g' $libvirtd_file
           sudo sed -i 's/^#unix_sock_rw_perms.*/unix_sock_rw_perms = "0770"/g' $libvirtd_file
           sudo service libvirtd restart
       fi
    fi
fi

# this fixes a bug in python-dib-elements. not all element scripts should be
# applied with sudo.
sudo chown -R $USER.$USER $HOME/.cache


# ssh configuration
if [ ! -f ~/.ssh/id_rsa.pub ]; then
    ssh-keygen -b 1024 -N '' -f ~/.ssh/id_rsa
fi

if [ ! -f ~/.ssh/authorized_keys ]; then
    touch ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
fi

sudo service libvirtd restart
sudo service openvswitch restart
# this often reports failure, even though the service is up
sudo service rabbitmq-server restart || true

# Make sure sshd is enabled and started by default
sudo systemctl enable sshd
sudo systemctl start sshd

sudo cp /root/stackrc $HOME/undercloudrc
source $HOME/undercloudrc

# Modify config.json as necessary
sudo sed -i "s/192.168.122.1/$NETWORK/g" /var/lib/heat-cfntools/cfn-init-data
sudo sed -i "s/\"user\": \"stack\",/\"user\": \"$USER\",/" /var/lib/heat-cfntools/cfn-init-data
sudo sed -i "s/eth1/$PUBLIC_INTERFACE/g" /var/lib/heat-cfntools/cfn-init-data

sudo sed -i "s/192.168.122.1/$NETWORK/g" /opt/stack/os-config-applier/templates/var/opt/undercloud-live/masquerade

touch /opt/stack/undercloud-live/.undercloud-configure
