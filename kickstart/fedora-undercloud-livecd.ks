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
    $UNDERCLOUD_LIVE_ROOT/undercloud-live/bin/undercloud-init.sh 

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

cat > /etc/rc.d/init.d/undercloud-live-init << EOF
#!/bin/bash
#
# undercloud-live-init: Undercloud live init script.
#
# chkconfig: 345 50 50
# description: Undercloud live init script.

/opt/stack/undercloud-live/undercloud-init.sh

EOF

chmod 755 /etc/rc.d/init.d/undercloud-live-init
/sbin/restorecon /etc/rc.d/init.d/undercloud-live-init
/sbin/chkconfig --add undercloud-live-init

%end
##############################################################################
