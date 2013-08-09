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

cp /home/jslagle/code/github/slagle/openstack/undercloud-live/bin/undercloud.sh $INSTALL_ROOT/root/

%end
##############################################################################


##############################################################################
# Post
##############################################################################
%post --log /root/undercloud-live-ks.log

# We need to be able to resolve addresses
echo nameserver 8.8.8.8 > /etc/resolv.conf

/root/undercloud.sh

%end
##############################################################################
