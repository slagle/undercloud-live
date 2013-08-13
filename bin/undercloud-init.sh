#!/bin/bash

set -eux

os=redhat
NETWORK=${NETWORK:-192.168.122.1}
PUBLIC_INTERFACE=${PUBLIC_INTERFACE:-eth1}

LIBVIRT_IP_ADDRESS=${LIBVIRT_IP_ADDRESS:-192.168.122.1}
LIBVIRT_NETWORK_RANGE_START=${LIBVIRT_NETWORK_RANGE_START:-192.168.122.2}
LIBVIRT_NETWORK_RANGE_END=${LIBVIRT_NETWORK_RANGE_END:-192.168.122.254}

# this fixes a bug in python-dib-elements. not all element scripts should be
# applied with sudo.
sudo chown $USER.$USER $HOME/.cache

if [ -e /opt/stack/undercloud-live/.undercloud-init ]; then
    echo undercloud-init has already run, exiting.
    exit
fi

# rabbitmq-server does not start with selinux enforcing.
sudo setenforce 0

# the current user needs to always connect to the system's libvirt instance
# when virsh is run
if [ ! -e /etc/profile.d/virsh.sh ]; then
    sudo su -c "cat >> /etc/profile.d/virsh.sh <<EOF

# Connect to system's libvirt instance
export LIBVIRT_DEFAULT_URI=qemu:///system

EOF
"
fi

# ssh configuration
if [ ! -f ~/.ssh/id_rsa.pub ]; then
    ssh-keygen -b 1024 -N '' -f ~/.ssh/id_rsa
fi

if [ ! -f ~/.ssh/authorized_keys ]; then
    touch ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
fi

sudo sed -i "s/192.168.122.1/$LIBVIRT_IP_ADDRESS/g" /etc/libvirt/qemu/networks/default.xml
sudo sed -i "s/192.168.122.2/$LIBVIRT_NETWORK_RANGE_START/g" /etc/libvirt/qemu/networks/default.xml
sudo sed -i "s/192.168.122.254/$LIBVIRT_NETWORK_RANGE_END/g" /etc/libvirt/qemu/networks/default.xml

sudo service libvirtd restart
sudo service openvswitch restart
sudo service rabbitmq-server restart

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

    exec sudo su -l $USER $0
fi

/opt/stack/tripleo-incubator/scripts/setup-network

sudo cp /root/stackrc $HOME/undercloudrc
source $HOME/undercloudrc

# Modify config.json as necessary
sudo sed -i "s/192.168.122.1/$NETWORK/g" /var/lib/heat-cfntools/cfn-init-data
sudo sed -i "s/\"user\": \"stack\",/\"user\": \"$USER\",/" /var/lib/heat-cfntools/cfn-init-data
sudo sed -i "s/eth1/$PUBLIC_INTERFACE/g" /var/lib/heat-cfntools/cfn-init-data

# starts all services and runs os-refresh-config (via os-collect-config
# service)
sudo systemctl isolate multi-user.target

sudo -E /opt/stack/tripleo-incubator/scripts/setup-neutron 192.0.2.2 192.0.2.3 192.0.2.0/24 192.0.2.1 ctlplane

touch /opt/stack/undercloud-live/.undercloud-init
