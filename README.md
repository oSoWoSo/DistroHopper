Want you try new Operating system? 

 try

[DistroHopper](https://github.com/oSoWoSo/DistroHopper)

![Hop](config/icons/hop.svg)

Quickly download, create and run VM of any(TODO) operating system.

Licensed under AGPL3
### Still Testing version!
![dh](distrohopper.png)


quickly create and run VMs

 As a base excellent [quickemu](https://github.com/quickemu-project/quickemu)
  
  you can download new distro with few clicks of a mouse
  
## GUI using yad

See it in action on youtube...

[![dh](https://img.youtube.com/vi/JtjIseqZMkQ/0.jpg)](https://www.youtube.com/watch?v=JtjIseqZMkQ)

  or command line?...

## TUI using fzf

[![tui](https://img.youtube.com/vi/gJ5hqYEskOw/0.jpg)](https://www.youtube.com/watch?v=gJ5hqYEskOw)


## .Desktop file generator
  It will simple generate .desktop files for every supported and downloaded VM in quickemu.
  So you can link it anywhere...

# Why I creating this?
  Because I wanna learn

- Linux

- Bash

- yad

- project management

And contribute to open source

 play with Quickemu

And easily add new distros to it



# How to run DistroHopper?

You need fullfill the requirement first...

Quickemu.

[![quickemu video: Replace VirtualBox with Bash &
QEMU](https://img.youtube.com/vi/AOTYWEgw0hI/0.jpg)](https://www.youtube.com/watch?v=AOTYWEgw0hI)

## Requirements (For running VMs)

-   [QEMU](https://www.qemu.org/) (*6.0.0 or newer*) **with GTK, SDL,
    SPICE & VirtFS support**
-   [bash](https://www.gnu.org/software/bash/) (*4.0 or newer*)
-   [Coreutils](https://www.gnu.org/software/coreutils/)
-   [EDK II](https://github.com/tianocore/edk2)
-   [grep](https://www.gnu.org/software/grep/)
-   [jq](https://stedolan.github.io/jq/)
-   [LSB](https://wiki.linuxfoundation.org/lsb/start)
-   [procps](https://gitlab.com/procps-ng/procps)
-   [python3](https://www.python.org/)
-   [macrecovery](https://github.com/acidanthera/OpenCorePkg/tree/master/Utilities/macrecovery)
-   [mkisofs](http://cdrtools.sourceforge.net/private/cdrecord.html)
-   [usbutils](https://github.com/gregkh/usbutils)
-   [util-linux](https://github.com/karelzak/util-linux)
-   [sed](https://www.gnu.org/software/sed/)
-   [socat](http://www.dest-unreach.org/socat/)
-   [spicy](https://gitlab.freedesktop.org/spice/spice-gtk)
-   [swtpm](https://github.com/stefanberger/swtpm)
-   [Wget](https://www.gnu.org/software/wget/)
-   [xdg-user-dirs](https://www.freedesktop.org/wiki/Software/xdg-user-dirs/)
-   [xrandr](https://gitlab.freedesktop.org/xorg/app/xrandr)
-   [zsync](http://zsync.moria.org.uk/)
-   [unzip](http://www.info-zip.org/UnZip.html)

### Installing Requirements

For Ubuntu, Arch and nixos systems the
[ppa](https://launchpad.net/~flexiondotorg/+archive/ubuntu/quickemu),
[AUR](https://aur.archlinux.org/packages/quickemu) or
[nix](https://github.com/NixOS/nixpkgs/tree/master/pkgs/development/quickemu)
packaging will take care of the dependencies. For other host
distributions or operating systems it will be necessary to install the
above requirements or their equivalents.

These examples may save a little typing

Debian:

    sudo apt install qemu bash coreutils ovmf grep jq lsb procps python3 genisoimage usbutils util-linux sed spice-client-gtk swtpm wget xdg-user-dirs zsync unzip

Fedora:

    sudo dnf install qemu bash coreutils edk2-tools grep jq lsb procps python3 genisoimage usbutils util-linux sed spice-gtk-tools swtpm wget xdg-user-dirs xrandr unzip
    
Void Linux:

    sudo xbps-install qemu bash coreutils grep jq procps-ng python3 util-linux sed spice-gtk swtpm usbutils wget xdg-user-dirs xrandr unzip zsync socat

# For Distrohopper to work you need `wget yad fzf` quickemu is included

# How to install DistroHopper?

 You need get copy of distrohopper
 
  If you want more stable, download latest [release](https://github.com/oSoWoSo/DistroHopper/releases) version
 
 If you want developer version... (could have bugs)
 
 `git clone https://github.com/oSoWoSo/DistroHopper`
 
 Enter created/unpacked distrohopper directory
 
 Then enter config directory
 
 `cd distrohopper/config`
 
 And run
 
 `./1stRun.sh`
 
 Now should be good to go...

# How to run

 Just run from terminal
 
 `dh`
 
 or for TUI version (Download and run from/into same directory)
 
 `dh -t`
 
# Desktop files

 All desktop files will be storred in your .config
 in directories /distrohopper/ready and supported
 
 Fell free to link them anywhere you want...
 
 

# Currently supported Distribution:

In screenshot above...

### Testing version!

# Project chat group:
If anyone wanna join, here is one 
[SimpleX](https://simplex.chat/contact#/?v=1-2&smp=smp%3A%2F%2FSkIkI6EPd2D63F4xFKfHk7I1UGZVNn6k1QWZ5rcyr6w%3D%40smp9.simplex.im%2FzmtsZwfTjwyynibt0bF6bb_xLWS9ce5A%23%2F%3Fv%3D1-2%26dh%3DMCowBQYDK2VuAyEAkMtz66wGfWb6VDn-_t_mVm3RFiFfOC3Hxye8Hm5tmVo%253D%26srv%3Djssqzccmrcws6bhmn77vgmhfjmhwlyr3u7puw4erkyoosywgl67slqqd.onion&data=%7B%22type%22%3A%22group%22%2C%22groupLinkId%22%3A%22o8KR0TOM0f2j33nO9goMRQ%3D%3D%22%7D) way

(check the software! even if you don't want chat about DistroHopper)
[Simplex website](https://simplex.chat)

# Without these amazing projects it wouldn't be posible:

[bash](https://www.gnu.org/software/bash/)

[QEMU](https://www.qemu.org/)

[quickemu](https://github.com/quickemu-project/quickemu)

GUI depends on
[yad](https://github.com/v1cont/yad)

TUI depends on
[fzf](https://github.com/junegunn/fzf)

[logo by](https://freesvg.org/by/OpenClipart)
