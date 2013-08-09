#!/bin/bash

# the current user needs to always connect to the system's libvirt instance
# when virsh is run
cat >> ~/.bashrc <<EOF

# Connect to system's libvirt instance
alias virsh='/usr/bin/virsh -c qemu:///system'

EOF

# ssh configuration
if [ ! -f ~/.ssh/id_rsa.pub ]; then
    ssh-keygen -b 1024 -N '' -f ~/.ssh/id_rsa
fi

if [ ! -f ~/.ssh/authorized_keys]; then
    touch ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
fi

sudo service libvirtd restart
sudo service openvswitch restart
sudo ovs-vsctl add-br brbm

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

    exec sudo su -l $USER bash
fi

/opt/stack/tripleo-incubator/scripts/setup-network
