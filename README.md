# undercloud-live

Tools and scripts to build an undercloud Live CD and configure an already
running system into an undercloud.

## bin/undercloud.sh
Run as current user to configure the current system into an undercloud.
sudo (with no password) privileges are required.

### Prerequisites
* sudo as root ability
* The following environment variables should be defined as URL's that can be
  used to download the needed images:

        $DEPLOY_RAMDISK_URL
        $DEPLOY_INITRAMFS_URL
        $OVERCLOUD_CONTROL_URL
        $OVERCLOUD_COMPUTE_URL

  If you prefer to provide the images a different way, just add them under
  /opt/stack/images, and comment out undercloud-images.sh in undercloud.sh.

### Caveats
* The firewalld service will be shutdown by undercloud.sh.  There's current a
  bug in the iptables configuration that prevents the overcloud that is still
  being investigated.

## kickstart/fedora-undercloud-livecd.ks
kickstart file that can be used to build an undercloud Live CD.

1. install fedora-kickstarts and livecd-tools if needed
1. set $UNDERCLOUD_LIVE_ROOT to the directory where undercloud-live is checked out
1. livecd-creator --verbose  --fslabel=Fedora-Undercloud-LiveCD --cache=/var/cache/live --releasever=19 --config=/path/to/undercloud-live/kickstart/fedora-undercloud-livecd.ks

This will produce a Fedora-Undercloud-LiveCD.iso file in the current directory.
To test it simply run:

    qemu-kvm -m 1024 Fedora-Undercloud-LiveCD.iso 
(you can also run it with 512 of ram, but it will be quite a bit slower)
