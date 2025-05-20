When installing from source, you will need to install the following requirements manually:

- [QEMU](https://www.qemu.org/) (*6.0.0 or newer*) **with GTK, SDL,
    SPICE & VirtFS support**
- [bash](https://www.gnu.org/software/bash/) (*4.0 or newer*)
- [Coreutils](https://www.gnu.org/software/coreutils/)
- [curl](https://curl.se/)
- [EDK II](https://github.com/tianocore/edk2)
- [gawk](https://www.gnu.org/software/gawk/)
- [grep](https://www.gnu.org/software/grep/)
- [glxinfo](https://gitlab.freedesktop.org/mesa/demos)
- [jq](https://stedolan.github.io/jq/)
- [LSB](https://wiki.linuxfoundation.org/lsb/start)
- [pciutils](https://github.com/pciutils/pciutils)
- [procps](https://gitlab.com/procps-ng/procps)
- [python3](https://www.python.org/)
- [mkisofs](http://cdrtools.sourceforge.net/private/cdrecord.html)
- [usbutils](https://github.com/gregkh/usbutils)
- [util-linux](https://github.com/karelzak/util-linux)
- [sed](https://www.gnu.org/software/sed/)
- [socat](http://www.dest-unreach.org/socat/)
- [spicy](https://gitlab.freedesktop.org/spice/spice-gtk)
- [swtpm](https://github.com/stefanberger/swtpm)
- [xdg-user-dirs](https://www.freedesktop.org/wiki/Software/xdg-user-dirs/)
- [xrandr](https://gitlab.freedesktop.org/xorg/app/xrandr)
- [zsync](http://zsync.moria.org.uk/)
- [unzip](http://www.info-zip.org/UnZip.html)

For Ubuntu, Arch and NixOS hosts, the
[ppa](https://launchpad.net/~flexiondotorg/+archive/ubuntu/quickemu),
[AUR](https://aur.archlinux.org/packages/quickemu) or
[nix](https://github.com/NixOS/nixpkgs/tree/master/pkgs/development/quickemu)
packaging will take care of the dependencies. For other host
distributions or operating systems it will be necessary to install the
above requirements or their equivalents.

These examples may save a little typing:

#### Install requirements on Debian hosts

This also applies to derivatives:

``` shell
sudo apt-get install bash coreutils curl genisoimage grep jq mesa-utils ovmf pciutils procps python3 qemu sed socat spice-client-gtk swtpm-tools unzip usbutils util-linux xdg-user-dirs xrandr zsync 
```

#### Install requirements on Fedora hosts

``` shell
sudo dnf install bash coreutils curl edk2-tools genisoimage grep jq mesa-demos pciutils procps python3 qemu sed socat spice-gtk-tools swtpm unzip usbutils util-linux xdg-user-dirs xrandr zsync
```

### Install requirements on Gentoo

Please note that you may have to use `sys-firmware/edk2-ovmf` instead of `sys-firmware/edk2-ovmf-bin` - depending on how your system is configured.

``` shell
sudo emerge --ask --noreplace app-emulation/qemu \
 app-shells/bash \
 sys-apps/coreutils \
 net-misc/curl \
 sys-firmware/edk2-ovmf-bin \
 sys-apps/gawk \
 sys-apps/grep \
 x11-apps/mesa-progs \
 app-misc/jq \
 sys-apps/pciutils \
 sys-process/procps \
 app-cdr/cdrtools \
 sys-apps/usbutils \
 sys-apps/util-linux \
 sys-apps/sed \
 net-misc/socat \
 app-emulation/spice \
 app-crypt/swtpm \
 x11-misc/xdg-user-dirs \
 x11-apps/xrandr \
 net-misc/zsync \
 app-arch/unzip
```

#### Install requirements on macOS hosts

Install the Quickemu requirements using brew:

``` shell
brew install bash cdrtools coreutils jq python3 qemu usbutils samba socat swtpm zsync
```

Now clone the project:

``` shell
git clone https://github.com/quickemu-project/quickemu
cd quickemu
```
