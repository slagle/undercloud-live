#!/bin/bash

set -eux

mkdir -p $HOME/.undercloud-live
LOG=$HOME/.undercloud-live/undercloud.log

exec > >(tee -a $LOG)
exec 2>&1

echo ##########################################################
echo Starting run of undercloud.sh at `date`

PIP_DOWNLOAD_CACHE=${PIP_DOWNLOAD_CACHE:-""}

if [ -z "$PIP_DOWNLOAD_CACHE" ]; then
    mkdir -p $HOME/.cache/pip
    PIP_DOWNLOAD_CACHE=$HOME/.cache/pip
    export PIP_DOWNLOAD_CACHE
fi

# /var/lock/subsys not always created in F19, and it is needed by openvswitch.
# See: https://bugzilla.redhat.com/show_bug.cgi?id=986667
sudo mkdir -p /var/lock/subsys

$(dirname $0)/install.sh

os=redhat
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
       fi
    fi
fi

# need to exec to pick up the new group
if ! id | grep libvirtd; then
    exec sudo su -l $USER $0
fi

# Switch over to use iptables instead of firewalld
# This is needed by os-refresh-config
sudo systemctl stop firewalld
sudo systemctl mask firewalld
sudo touch /etc/sysconfig/iptables
sudo systemctl enable iptables
sudo systemctl enable ip6tables
sudo systemctl start iptables
sudo systemctl start ip6tables

# starts all services and run os-refresh-config
sudo systemctl daemon-reload
UCL_USER=$USER sudo -E os-collect-config --one-time

echo "undercloud.sh run complete."
