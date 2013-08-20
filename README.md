# undercloud-live

Tools and scripts to build an undercloud Live CD and configure an already
running Fedora 19 system into an undercloud.  The script is meant to be run on
physical hardware.  However, it can also be used on a vm, but you need to make
sure that the vm you intend to configure as a undercloud as been configured to
use nested kvm [1][2].

To get started, clone this repo to your home directory:

    $ cd
    $ git clone https://github.com/slagle/undercloud-live.git

## bin/undercloud.sh
Run as current user to configure the current system into an undercloud like so:

    $ undercloud-live/bin/undercloud.sh

The script logs to ~/.undercloud-live/undercloud.log.  If there is an error
applying one of the diskimage-builder elements, you will see a prompt to
continue or not.  This is for debugging purposes.

Once the script has completed, you should have a functioning undercloud.  At
this point, you would move onto the next steps of building images for and
deploying an overcloud.  These steps are also scripted in the
undercloud-images.sh and undercloud-deploy-overcloud.sh scripts.  So you can
just run these if you prefer to do that instead:

    $ undercloud-live/bin/undercloud-images.sh
    $ undercloud-live/bin/undercloud-deploy-overcloud.sh


### Prerequisites
* Only works on Fedora 19
* sudo as root ability

### Caveats
* If you reboot the undercloud system, you will need to rerun
  bin/undercloud-network.sh
* The firewalld service will be shutdown by undercloud.sh.  There's current a
  bug in the iptables configuration that prevents the overcloud that is still
  being investigated.
* SELinux is set to Permissive mode.  Otherwise, rabbitmq-server will not
  start.  
  See: https://bugzilla.redhat.com/show_bug.cgi?id=998682  
  Note: we will be switching to use qpid soon

## kickstart/fedora-undercloud-livecd.ks
kickstart file that can be used to build an undercloud Live CD.

1. install fedora-kickstarts and livecd-tools if needed
1. set $UNDERCLOUD_LIVE_ROOT to the directory where undercloud-live is checked out
1. livecd-creator --verbose  --fslabel=Fedora-Undercloud-LiveCD --cache=/var/cache/live --releasever=19 --config=/path/to/undercloud-live/kickstart/fedora-undercloud-livecd.ks

This will produce a Fedora-Undercloud-LiveCD.iso file in the current directory.
To test it simply run:

    qemu-kvm -m 1024 Fedora-Undercloud-LiveCD.iso 
(you can also run it with 512 of ram, but it will be quite a bit slower)

# References

[1:] http://www.server-world.info/en/note?os=Fedora_19&p=kvm&f=8
[2:] https://fedoraproject.org/wiki/QA:Testcase_KVM_nested_virt
