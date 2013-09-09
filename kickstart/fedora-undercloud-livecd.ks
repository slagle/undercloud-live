# Fedora TripleO Undercloud

%include /usr/share/spin-kickstarts/fedora-livecd-xfce.ks

# Need bigger / partition than default
part / --size 6144 --fstype ext4

# rabbitmq doesn't start when selinux is enforcing
selinux --permissive

# we need a network to setup the undercloud
network --activate --device=eth0 --bootproto=dhcp

##############################################################################
# Packages
##############################################################################
%packages

git
python-pip

%end
##############################################################################


##############################################################################
# Post --nochroot
##############################################################################
%post --nochroot

cd $INSTALL_ROOT/root
git clone https://github.com/slagle/undercloud-live

mkdir -p $INSTALL_ROOT/root/.cache/image-create

# pip is slow, just copy this into the chroot for now
# cp -r /home/jslagle/.cache/image-create/pip $INSTALL_ROOT/root/.cache/image-create/
# chown -R root.root $INSTALL_ROOT/root/.cache/image-create
# git clone is slow, just copy into chroot for now
# cp -r /home/jslagle/.cache/image-create/repository-sources $INSTALL_ROOT/root/.cache/image-create/
# chown -R root.root $INSTALL_ROOT/root/.cache/image-create

# Add cached Fedora Cloud images.
# TODO: need to come from more permanent location
cd $INSTALL_ROOT/root/.cache/image-create
curl -O http://file.rdu.redhat.com/~jslagle/latest-Cloud-x86_64-latest.tgz
curl -o fedora-latest.x86_64.qcow2 http://file.rdu.redhat.com/~jslagle/Fedora-x86_64-19-20130627-sda.qcow2
    
%end
##############################################################################


##############################################################################
# Post
##############################################################################
%post --log /opt/stack/kickstart.log --erroronfail

set -ex

# We need to be able to resolve addresses
echo nameserver 8.8.8.8 > /etc/resolv.conf

# Add a cache for pip
mkdir -p /var/cache/pip
export PIP_DOWNLOAD_CACHE=/var/cache/pip

# Install the undercloud
/root/undercloud-live/bin/undercloud-install.sh

# move diskimage-builder cache into stack user's home dir so it can be reused
# during image builds.
mkdir -p /home/stack/.cache
mv /root/.cache/image-create /home/stack/.cache/
mkdir -p /home/stack/.cache/image-create/yum
mkdir -p /home/stack/.cache/image-create/ccache
chown -R stack.stack /home/stack/.cache

# setup users to be able to run sudo with no password
sed -i "s/# %wheel/%wheel/" /etc/sudoers

# Install our setup services
cp -t /lib/systemd/system \
    /root/undercloud-live/kickstart/undercloud-configure.service \
    /root/undercloud-live/kickstart/undercloud-network.service \
    /root/undercloud-live/kickstart/undercloud-setup.service \
    /root/undercloud-live/kickstart/os-collect-config-one-time.service
ln -s '/usr/lib/systemd/system/undercloud-configure.service' \
    '/etc/systemd/system/multi-user.target.wants/undercloud-configure.service'
ln -s '/usr/lib/systemd/system/undercloud-setup.service' \
    '/etc/systemd/system/multi-user.target.wants/undercloud-setup.service'
ln -s '/usr/lib/systemd/system/undercloud-network.service' \
    '/etc/systemd/system/multi-user.target.wants/undercloud-network.service'
ln -s '/usr/lib/systemd/system/os-collect-config-one-time.service' \
    '/etc/systemd/system/multi-user.target.wants/os-collect-config-one-time.service'

# tmpfs mount dirs for:
# yum cache
# ccache
# /opt/stack/images
# /var/lib/glance/images
mkdir -p /opt/stack/images
chgrp stack /opt/stack/images
chmod 775 /opt/stack/images
export STACK_ID=`id -u stack`
export STACK_GROUP_ID=`id -g stack`
export GLANCE_ID=`id -u glance`
export GLANCE_GROUP_ID=`id -g glance`
export NOVA_ID=`id -u nova`
export NOVA_GROUP_ID=`id -g nova`
cat << EOF >> /etc/fstab
tmpfs /home/stack/.cache/image-create/ccache tmpfs rw,uid=$STACK_ID,gid=$STACK_GROUP_ID 0 0
tmpfs /home/stack/.cache/image-create/yum tmpfs rw,uid=$STACK_ID,gid=$STACK_GROUP_ID 0 0
tmpfs /opt/stack/images tmpfs rw,uid=$STACK_ID,gid=$STACK_GROUP_ID 0 0
tmpfs /var/lib/glance/images tmpfs rw,uid=$GLANCE_ID,gid=$GLANCE_GROUP_ID 0 0
tmpfs /var/lib/nova/instances tmpfs rw,uid=$NOVA_ID,gid=$NOVA_GROUP_ID 0 0
EOF

# we need grub2 back (removed by dib elements)
yum -y install grub2-tools grub2 grub2-efi

# Empty root password (easier to debug)
passwd -d root

# Switch over to use iptables instead of firewalld
# This is needed by os-refresh-config
# systemctl mask firewalld
ln -s '/dev/null' '/etc/systemd/system/firewalld.service'

touch /etc/sysconfig/iptables
# systemctl enable iptables
ln -s '/usr/lib/systemd/system/iptables.service' '/etc/systemd/system/basic.target.wants/iptables.service'
# systemctl enable ip6tables
ln -s '/usr/lib/systemd/system/ip6tables.service' '/etc/systemd/system/basic.target.wants/ip6tables.service'


%end
##############################################################################
