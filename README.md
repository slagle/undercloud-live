undercloud-live
===============

Tools and scripts to build an undercloud Live CD and configure an alredy
running system into an undercloud.

bin/undercloud.sh
-----------------
Run as current user to configure the current system into an undercloud.
sudo (with no password) privileges are required.

kickstart/fedora-undercloud-livecd.ks
-------------------------------------
kickstart file that can be used to build an undercloud Live CD.

1. install fedora-kickstarts and livecd-tools if needed
1. set $UNDERCLOUD_LIVE_ROOT to the directory where undercloud-live is checked out
1. livecd-creator --verbose  --fslabel=Fedora-Undercloud-LiveCD --cache=/var/cache/live --releasever=19 --config=/path/to/undercloud-live/kickstart/fedora-undercloud-livecd.ks

This will produce a Fedora-Undercloud-LiveCD.iso file in the current directory.
To test it simply run:

    qemu-kvm -m 1024 Fedora-Undercloud-LiveCD.iso 
(you can also run it with 512 of ram, but it will be quite a bit slower)
