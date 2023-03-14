Welcome to

# [DistroHooper](https://github.com/oSoWoSo/DistroHooper)
 Licensed under AGPL3
### Still Testing version!
![quickgui](distrohopper.png)


quickly create and run VMs

 As a base excellent [quickemu](https://github.com/quickemu-project/quickemu)

I added:

## quickgui
  using yad

### .Desktop file generator
  It will simple generate .desktop files for every supported VM in quickemu.
  So you can copy it anywhere...
  
  And I mean every supported distro.
  
  you can download new distro with few clicks of a mouse
  
  You need to run quickgui just for update supported distros.

### Simple GUI using yad --notebook

See it in action on youtube...

[![quickgui](https://img.youtube.com/vi/JtjIseqZMkQ/0.jpg)](https://www.youtube.com/watch?v=JtjIseqZMkQ)

  or command line?...


## quicktui
  using fzf

[![quicktui](https://img.youtube.com/vi/gJ5hqYEskOw/0.jpg)](https://www.youtube.com/watch?v=gJ5hqYEskOw)

#

Quickemu.

[![quickemu video: Replace VirtualBox with Bash &
QEMU](https://img.youtube.com/vi/AOTYWEgw0hI/0.jpg)](https://www.youtube.com/watch?v=AOTYWEgw0hI)

## Requirements

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

# Currently supported Distribution:

### Ubuntu Flavours

All the official Ubuntu flavours are supported, just replace `ubuntu`
with your preferred flavour.

-   `kubuntu` (Kubuntu)
-   `lubuntu` (Lubuntu)
-   `ubuntu-budgie` (Ubuntu Budgie)
-   `ubuntukylin` (Ubuntu Kylin)
-   `ubuntu-mate` (Ubuntu MATE)
-   `ubuntustudio` (Ubuntu Studio)
-   `ubuntu` (Ubuntu)
-   `ubuntu-unity` (Ubuntu Unity)
-   `xubuntu` (Xubuntu)

## Other Operating Systems

-   `agarimos` (AgarimOS)
-   `alma` (Alma Linux)
-   `alpine` (Alpine Linux)
-   `android` (Android x86)
-   `archcraft` (Archcraft)
-   `archlinux` (Arch Linux)
-   `arcolinux` (Arco Linux)
-   `batocera` (Batocera)
-   `blendos` (BlendOS)
-   `cachyos` (CachyOS)
-   `centos-stream` (CentOS Stream)
-   `debian` (Debian)
-   `deepin` (Deepin)
-   `devuan` (Devuan)
-   `dietpi` (DietPi)
-   `dragonflybsd` (DragonFlyBSD)
-   `elementary` (elementary OS)
-   `endeavouros` (EndeavourOS)
-   `endless` (Endless OS)
-   `fedora` (Fedora)
-   `freebsd` (FreeBSD)
-   `freedos` (FreeDOS)
-   `fvoid` (F\-Void)
-   `gabeeos` (Gabee OS)
-   `garuda` (Garuda Linux)
-   `gentoo` (Gentoo)
-   `ghostbsd` (GhostBSD)
-   `haiku` (Haiku)
-   `kali` (Kali)
-   `kdeneon` (KDE Neon)
-   `kolibrios` (KolibriOS)
-   `linuxmint` (Linux Mint)
-   `lmde` (Linux Mint Debian Edition)
-   `mageia` (Mageia)
-   `manjaro` (Manjaro)
-   `mxlinux` (MX Linux)
-   `netboot` (netboot.xyz)
-   `netbsd` (NetBSD)
-   `nixos` (NixOS)
-   `openbsd` (OpenBSD)
-   `opensuse` (openSUSE)
-   `oraclelinux` (Oracle Linux)
-   `popos` (Pop!\_OS)
-   `reactos` (ReactOS)
-   `rebornos` (RebornOS)
-   `rockylinux` (Rocky Linux)
-   `siduction` (siduction)
-   `slackware` (Slackware)
-   `solus` (Solus)
-   `steamos` (Steam OS)
-   `tails` (Tails)
-   `truenas-core` (TrueNAS Core)
-   `truenas-scale` (TrueNAS Scale)
-   `void` (Void Linux)
-   `voidpup` (VoidPup)
-   `vxlinux` (VX Linux)
-   `xerolinux` (XeroLinux)
-   `zorin` (Zorin OS)

-   `macos` (MacOS)
-   `windows` (Windows)

### Testing version!

# Without these amazing projects it wouldn't be posible:

[bash](https://www.gnu.org/software/bash/)

[QEMU](https://www.qemu.org/)

[quickemu](https://github.com/quickemu-project/quickemu)

GUI depends on
[yad](https://github.com/v1cont/yad)

TUI depends on
[fzf](https://github.com/junegunn/fzf)
