## [Creating macOS Guests](https://github.com/quickemu-project/quickemu/wiki/03-Create-macOS-virtual-machines#automatically-create-macos-guests) 🍏

**Installing macOS in a VM can be a bit finicky, if you encounter problems, [check the Discussions](https://github.com/quickemu-project/quickemu/discussions) for solutions or ask for help there** 🛟

`quickget` automatically downloads a macOS recovery image and creates a virtual machine configuration.

``` shell
quickget macos big-sur
quickemu --vm macos-big-sur.conf
```

macOS `mojave`, `catalina`, `big-sur`, `monterey`, `ventura` and
`sonoma` are supported.

- Use cursor keys and enter key to select the **macOS Base System**
- From **macOS Utilities**
    - Click **Disk Utility** and **Continue**
        - Select `QEMU HARDDISK Media` (\~103.08GB) from the list (on
            Big Sur and above use `Apple Inc. VirtIO Block Device`) and
            click **Erase**.
        - Enter a `Name:` for the disk
        - If you are installing macOS Mojave or later (Catalina, Big
            Sur, Monterey, Ventura and Sonoma), choose any of the APFS options
            as the filesystem. MacOS Extended may not work.
    - Click **Erase**.
    - Click **Done**.
    - Close Disk Utility
- From **macOS Utilities**
    - Click **Reinstall macOS** and **Continue**
- Complete the installation as you normally would.
    - On the first reboot use cursor keys and enter key to select
        **macOS Installer**
    - On the subsequent reboots use cursor keys and enter key to
        select the disk you named
- Once you have finished installing macOS you will be presented with
    an the out-of-the-box first-start wizard to configure various
    options and set up your username and password
- OPTIONAL: After you have concluded the out-of-the-box wizard, you
    may want to enable the TRIM feature that the computer industry
    created for SSD disks. This feature in our macOS installation will
    allow QuickEmu to compact (shrink) your macOS disk image whenever
    you delete files inside the Virtual Machine. Without this step your
    macOS disk image will only ever get larger and will not shrink even
    when you delete lots of data inside macOS.
   - To enable TRIM, open the Terminal application and type the
        following command followed by pressing <kbd>enter</kbd> to tell macos to use the TRIM command on the hard disk when files are deleted:

``` shell
sudo trimforce enable
```

You will be prompted to enter your account's password to gain the
privilege needed. Once you've entered your password and pressed <kbd>enter</kbd> the command will request confirmation in the form of two questions that require you to type
<kbd>y</kbd> (for a "yes" response) followed by
<kbd>enter</kbd> to confirm.

If you press <kbd>enter</kbd> without first typing <kbd>y</kbd> the system will consider that a negative response as though you said "no":

``` plain
IMPORTANT NOTICE: This tool force-enables TRIM for all relevant attached devices, even though such devices may not have been validated for data integrity while using TRIM. Use of this tool to enable TRIM may result in unintended data loss or data corruption. It should not be used in a commercial operating environment or with important data. Before using this tool, you should back up all of your data and regularly back up data while TRIM is enabled. This tool is provided on an "as is" basis. APPLE MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING THIS TOOL OR ITS USE ALONE OR IN COMBINATION WITH YOUR DEVICES, SYSTEMS, OR SERVICES. BY USING THIS TOOL TO ENABLE TRIM, YOU AGREE THAT, TO THE EXTENT PERMITTED BY APPLICABLE LAW, USE OF THE TOOL IS AT YOUR SOLE RISK AND THAT THE ENTIRE RISK AS TO SATISFACTORY QUALITY, PERFORMANCE, ACCURACY AND EFFORT IS WITH YOU.
Are you sure you with to proceed (y/N)?
```

And a second confirmation once you've confirmed the previous one:

``` plain
Your system will immediately reboot when this is complete.
Is this OK (y/N)?
```

As the last message states, your system will automatically reboot as
soon as the command completes.

The default macOS configuration looks like this:

``` shell
guest_os="macos"
img="macos- big-sur/RecoveryImage.img"
disk_img="macos- big-sur/disk.qcow2"
macos_release=" big-sur"
```

- `guest_os="macos"` instructs Quickemu to optimise for macOS.
- `macos_release=" big-sur"` instructs Quickemu to optimise for a
    particular macOS release.
    - For example VirtIO Network and Memory Ballooning are available
        in Big Sur and newer, but not previous releases.
    - And VirtIO Block Media (disks) are supported/stable in Catalina
        and newer.

# macOS compatibility

There are some considerations when running macOS via Quickemu.

- Supported macOS releases:
    - Mojave
    - Catalina
    - Big Sur
    - Monterey
    - Ventura
    - Sonoma
- `quickemu` will automatically download the required [OpenCore](https://github.com/acidanthera/OpenCorePkg) bootloader and OVMF firmware from [OSX-KVM](https://github.com/kholia/OSX-KVM).
- Optimised by default, but no GPU acceleration is available.
    - Host CPU vendor is detected and guest CPU is optimised accordingly.
    - [VirtIO Block Media](https://www.kraxel.org/blog/2019/06/macos-qemu-guest/) is used for the system disk where supported.
    - [VirtIO `usb-tablet`](http://philjordan.eu/osx-virt/) is used for the mouse.
    - VirtIO Network (`virtio-net`) is supported and enabled on macOS Big Sur and newer, but earlier releases use `vmxnet3`.
    - VirtIO Memory Ballooning is supported and enabled on macOS Big Sur and newer but disabled for other support macOS releases.
- USB host and SPICE pass-through is:
    - UHCI (USB 2.0) on macOS Catalina and earlier.
    - XHCI (USB 3.0) on macOS Big Sur and newer.
- Display resolution can be changed via `quickemu` using `--width` and `--height` command line arguments.
- **Full Duplex audio requires [VoodooHDA OC](https://github.com/chris1111/VoodooHDA-OC) or pass-through a USB audio-device to the macOS guest VM**.
    - NOTE! [Gatekeeper](https://disable-gatekeeper.github.io/) and [System Integrity Protection (SIP)](https://developer.apple.com/documentation/security/disabling_and_enabling_system_integrity_protection) need to be disabled to install VoodooHDA OC
- File sharing between guest and host is available via [virtio-9p](https://wiki.qemu.org/Documentation/9psetup) and [SPICE
    webdavd](https://gitlab.gnome.org/GNOME/phodav/-/merge_requests/24).
- Copy/paste via SPICE agent is **not available on macOS**.

# macOS App Store

If you see *"Your device or computer could not be verified"* when you try to login to the App Store, make sure that your wired ethernet device is `en0`. Use `ifconfig` in a terminal to verify this.

If the wired ethernet device is not `en0`, then then go to *System Preferences* -\> *Network*, delete all the network devices and apply the
changes. Next, open a terminal and run the following:

``` shell
sudo rm /Library/Preferences/SystemConfiguration/NetworkInterfaces.plist
```

Now reboot, and the App Store should work.

There may be further advice and information about macOS guests in the project [wiki](https://github.com/quickemu-project/quickemu/wiki/03-Create-macOS-virtual-machines#automatically-create-macos-guests).
