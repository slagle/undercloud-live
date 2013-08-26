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

# pip is slow, just copy this into the chroot for now
cp -r /home/jslagle/.cache/image-create/pip $INSTALL_ROOT/var/cache/
chown -R root.root $INSTALL_ROOT/var/cache/pip
# git clone is slow, just copy into chroot for now
mkdir -p $INSTALL_ROOT/root/.cache/image-create
cp -r /home/jslagle/.cache/image-create/repository-sources $INSTALL_ROOT/root/.cache/image-create/
chown -R root.root $INSTALL_ROOT/root/.cache/image-create

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
chown -R stack.stack /home/stack/.cache

# setup users to be able to run sudo with no password
sed -i "s/# %wheel/%wheel/" /etc/sudoers

# Install our setup services
cp -t /lib/systemd/system \
    /root/undercloud-live/kickstart/undercloud-configure.service \
    /root/undercloud-live/kickstart/undercloud-network.service \
    /root/undercloud-live/kickstart/undercloud-setup.service
ln -s '/usr/lib/systemd/system/undercloud-configure.service' \
    '/etc/systemd/system/multi-user.target.wants/undercloud-configure.service'
ln -s '/usr/lib/systemd/system/undercloud-setup.service' \
    '/etc/systemd/system/multi-user.target.wants/undercloud-setup.service'
ln -s '/usr/lib/systemd/system/undercloud-network.service' \
    '/etc/systemd/system/multi-user.target.wants/undercloud-network.service'


%end
##############################################################################
