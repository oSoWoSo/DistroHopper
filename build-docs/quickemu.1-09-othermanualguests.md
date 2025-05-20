### [Custom Linux guests](https://github.com/quickemu-project/quickemu/wiki/02-Create-Linux-virtual-machines#manually-create-linux-guests)

Or you can download a Linux image and manually create a VM
configuration.

- Download a .iso image of a Linux distribution
- Create a VM configuration file; for example `debian-bullseye.conf`

``` shell
guest_os="linux"
disk_img="debian-bullseye/disk.qcow2"
iso="debian-bullseye/firmware-11.0.0-amd64-DVD-1.iso"
```

- Use `quickemu` to start the virtual machine:

``` shell
quickemu --vm debian-bullseye.conf
```

- Complete the installation as normal.
- Post-install:
    - Install the SPICE agent (`spice-vdagent`) in the guest to enable
        copy/paste and USB redirection.
    - Install the SPICE WebDAV agent (`spice-webdavd`) in the guest to
        enable file sharing.

## Supporting old Linux distros

If you want to run an old Linux , from 2016 or earlier, change the `guest_os` to `linux_old`.
This will enable the `vmware-svga` graphics driver which is better supported on older distros.