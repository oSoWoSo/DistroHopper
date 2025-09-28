![](https://img.shields.io/github/stars/oSoWoSo/DistroHopper?style=for-the-badge&color=8BC53F&logo=instatus&logoColor=000000)
![](https://img.shields.io/github/forks/oSoWoSo/DistroHopper?style=for-the-badge&color=8BC53F&logo=git&logoColor=000000)
![](https://img.shields.io/github/license/oSoWoSo/DistroHopper?style=for-the-badge&color=8BC53F&logo=apache&logoColor=000000)
![](https://img.shields.io/github/repo-size/oSoWoSo/DistroHopper?style=for-the-badge&color=8BC53F&logo=files&logoColor=000000)

![](https://img.shields.io/github/last-commit/oSoWoSo/DistroHopper?style=for-the-badge&color=8BC53F&logo=codeigniter&logoColor=000000)
![](https://img.shields.io/badge/language-shell-green?style=for-the-badge&color=8BC53F&logo=sharp&logoColor=000000)
![](https://img.shields.io/badge/gitmoji-%20😜%20😍-FFDD67.svg?style=for-the-badge&color=8BC53F&logo=sharp&logoColor=000000&alt="Gitmoji")

---

# Looking to try out a new operating system?

 try

# **DistroHopper**
Quickly download, create and run VM of any#TODO operating system.

Linux![Tux](docs/tux23.png) required...

---

Click on Hop for latest download

[![Hop](docs/hop120.png)](https://sourceforge.net/projects/distrohopper/files/latest/download)

[![Donate](https://liberapay.com/assets/widgets/donate.svg)](https://liberapay.com/zenobit/donate)

Licensed under AGPL3
# Still Beta version!
<details>
  <summary>Click for screenshot</summary>
<img src="docs/distrohopper.png">
</details>

 As a base excellent [quickemu](https://github.com/quickemu-project/quickemu) (Link to project page)

[![quickemu video: Replace VirtualBox with Bash &
QEMU](https://img.youtube.com/vi/AOTYWEgw0hI/0.jpg)](https://www.youtube.com/watch?v=AOTYWEgw0hI)


  You can download new distro with **few clicks** of a mouse

# Features
 - GUI using yad (on youtube)

[![dh](https://img.youtube.com/vi/RrFQECcwLRA/0.jpg)](https://www.youtube.com/watch?v=RrFQECcwLRA)

 - TUI using fzf (on youtube)

[![tui](https://img.youtube.com/vi/gJ5hqYEskOw/0.jpg)](https://www.youtube.com/watch?v=gJ5hqYEskOw)

 - Desktop(shortcuts) entries generator

 - Set dir where VMs will be stored

 - Install DistroHopper systemwide

 - Portable mode (dependecies still must be installed)

 - Add new operating system to quickget (bit easier)

 - Copy all downloaded ISOs to destination directory

 - Translate DistroHopper (Currently supported English and Czech language)


Developed in English and translated into Czech language.

## Welcome translations!

---

# Why am I doing it?
  Because I wanna learn

- Linux

- Bash

- yad

- project management

And contribute to open source

 play with Quickemu

And easily add new distros to it

---

## How to run DistroHopper?

You need fullfill the requirement first...

## Requirements (For running VMs)
-   [QEMU](https://www.qemu.org/) (*6.0.0 or newer*) **with GTK, SDL, SPICE & VirtFS support**
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

	If you install DistroHopper, it should take care of dependencies on Arch, Debian, Ubuntu, openSuse and Fedora

### For DistroHopper to work you need

  `wget yad fzf`

 quickemu is included

 For adding new distros, or adding/improving translations you will need also meld.

# How to install DistroHopper?

 You need get copy of distrohopper

  If you want more stable experience, download latest release from

#### [GitHub](https://github.com/oSoWoSo/DistroHopper/releases) or SourceForge [![SourceForge](https://img.shields.io/sourceforge/dt/distrohopper.svg)](https://sourceforge.net/projects/distrohopper/files/latest/download)

---

 If you want latest developer version... (could have bugs and break anytime)

 Or you want translate DistroHopper

 `git clone https://github.com/oSoWoSo/DistroHopper`

 Enter created/unpacked distrohopper directory

 Now you should be good to go...

---

# How to run DistroHopper

 Just run from terminal

 `./dh`

  And you will see what next...

  I am usually run DistroHopper as:

 `./dh m r s l && ./dh i && dh g`

 (But...)

## Desktop files

 All desktop files will be storred in your .config/distrohopper
 in directories *ready* and *supported*

 Fell free to copy them anywhere you want...

### Currently supported Operating Systems and tools:
agarimos
alma
alpine
android
arch
archcraft
arco
artix
athenaos
batocera
biglinux
blendos
bodhi
cachyos
centos-stream
cereus
chimera
debian
deepin
devuan
dietpi
dragonflybsd
edubuntu
elementary
endeavouros
endless
fedora
freebsd
freedos
fvoid
gabeeos
garuda
gentoo
ghostbsd
haiku
holoiso
kali
kdeneon
kolibrios
kubuntu
lite
lmde
mageia
manjaro
mint
miyo
mx
netboot
netbsd
nixos
lubuntu
macos
openbsd
openindiana
opensuse
oracle
popos
reactos
rebornos
rocky
siduction
slackware
slax
slitaz
solus
tails
tinycore
truenas-core
truenas-scale
tuxedoos
ubuntu
ubuntu-budgie
ubuntucinnamon
ubuntukylin
ubuntu-mate
ubuntu-server
ubuntustudio
ubuntu-unity
vanillaos
ventoy
void
voidpup
vx
windows
xero
xubuntu
zorin


Also with posible planned: [in discusion](https://github.com/oSoWoSo/DistroHopper/discussions/9)

---

#### [discuss](https://github.com/oSoWoSo/DistroHopper/discussions) on github

# Join DistroHopper chat group:
[![SimpleX](docs/simplex.svg)](https://simplex.chat/contact#/?v=1-2&smp=smp%3A%2F%2FSkIkI6EPd2D63F4xFKfHk7I1UGZVNn6k1QWZ5rcyr6w%3D%40smp9.simplex.im%2FzmtsZwfTjwyynibt0bF6bb_xLWS9ce5A%23%2F%3Fv%3D1-2%26dh%3DMCowBQYDK2VuAyEAkMtz66wGfWb6VDn-_t_mVm3RFiFfOC3Hxye8Hm5tmVo%253D%26srv%3Djssqzccmrcws6bhmn77vgmhfjmhwlyr3u7puw4erkyoosywgl67slqqd.onion&data=%7B%22type%22%3A%22group%22%2C%22groupLinkId%22%3A%22o8KR0TOM0f2j33nO9goMRQ%3D%3D%22%7D) (click SimpleX logo)

(check the software! even if you don't want chat about DistroHopper)
[Simplex website](https://simplex.chat)

# Without these amazing projects it wouldn't be posible:

#### [bash](https://www.gnu.org/software/bash/)

#### [QEMU](https://www.qemu.org/)

#### [quickemu](https://github.com/quickemu-project/quickemu)

GUI depends on
#### [yad](https://github.com/v1cont/yad)

TUI depends on
#### [fzf](https://github.com/junegunn/fzf)

----

For

- easy of use

#### [fish](https://fishshell.com)

- commiting and working with github

#### [lazygit](https://github.com/jesseduffield/lazygit)

#### [opencommit](https://github.com/di-sukharev/opencommit)

- Editing

#### [geany](https://geany.org/)

#### [Kate](https://apps.kde.org/kate)

- diff

#### [Meld](https://meld.app/)

- Logo and icons

#### [GIMP](https://www.gimp.org)

and

#### [Inkscape](https://inkscape.org)

#### [logo by](https://freesvg.org/by/OpenClipart) bit repaired by me..

- Updating translation

#### [Poedit](https://poeditor.com/)

Everything done on

#### [Void Linux](https://voidlinux.org)

---

# Mirrored on

#### [GitHub](https://github.com/oSoWoSo/DistroHopper)

#### [SourceForge](https://sourceforge.net/projects/distrohopper)

#### [Disroot](https://git.disroot.org/oSoWoSo/DistroHopper)

#### [Codeberg](https://codeberg.org/oSoWoSo/DistroHopper)

#### [GitLab](https://gitlab.com/osowoso/distrohopper)

#### [SourceHut](https://git.sr.ht/~osowoso/DistroHopper)

---

For Homepage click on Hop

[![Hop](docs/hop120.png)](https://dh.osowoso.xyz/)

# donate
[![Donate](https://liberapay.com/assets/widgets/donate.svg)](https://liberapay.com/zenobit/donate)

@zen0bit at github

mailto: <zenobit@osowoso.xyz>

#### parent site [oSoWoSo](https://osowoso.xyz)

