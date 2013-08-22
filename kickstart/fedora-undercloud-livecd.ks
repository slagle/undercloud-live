# Fedora TripleO Undercloud

%include /usr/share/spin-kickstarts/fedora-livecd-desktop.ks

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

mkdir -p $INSTALL_ROOT/opt/stack/undercloud-live
cp -t $INSTALL_ROOT/opt/stack/undercloud-live/ \
    $UNDERCLOUD_LIVE_ROOT/undercloud-live/bin/undercloud-install.sh 

%end
##############################################################################


##############################################################################
# Post
##############################################################################
%post --log /opt/stack/undercloud-live/kickstart.log

set -x

# We need to be able to resolve addresses
echo nameserver 8.8.8.8 > /etc/resolv.conf

/opt/stack/undercloud-live/undercloud-install.sh

# setup users to be able to run sudo with no password
sed -i "s/# %wheel/%wheel/" /etc/sudoers

%end
##############################################################################
