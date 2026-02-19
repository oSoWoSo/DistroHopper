# This repository contains a multiple tools
Can be used together with quickemu  
# <p align="center">Welcome <img src="https://dh.osowoso.org/hop120.png" align="middle" width="80" /> DistroHoppers</p>
## I made some user interfaces for quickemu...

🦚
[dh](https://github.com/oSoWoSo/DistroHopper/blob/all/dh) GUI and TUI using yad

🕊️
[quickfzf](https://github.com/oSoWoSo/DistroHopper/blob/all/quickfzf) TUI using fzf

🐲
[quicktui](https://github.com/oSoWoSo/DistroHopper/blob/all/quicktui) TUI using gum (🚧 usable but under heavy development)

🐅
[qrun](https://github.com/oSoWoSo/DistroHopper/blob/all/qrun) TUI using gum
[![asciicast](https://asciinema.org/a/fPcYGWhF8aGoJJ5M30Q1CWdqe.svg)](https://asciinema.org/a/fPcYGWhF8aGoJJ5M30Q1CWdqe)

🦈
[q](https://github.com/oSoWoSo/DistroHopper/blob/all/q) TUI using gum

and

### open source version without removed proprietary OSes (Mac,Windows)
[quickget-](https://github.com/oSoWoSo/DistroHopper/tree/open-source-only/quickget)

### Extended version with more distros then upstream quickemu
[quickget+](https://github.com/oSoWoSo/DistroHopper/tree/quickget-extended/quickget)

### quickget+ with gum UI
[quickget+gum](https://github.com/oSoWoSo/DistroHopper/tree/quickget-gum-UI/quickget) 

### quickget+ with easybashgui UI
[quickget+ebg](https://github.com/oSoWoSo/DistroHopper/tree/quickget-ebg-UI/quickget)

Enjoy...

[repo](https://github.com/oSoWoSo/DistroHopper/)

Everything could work
# Thanks to:
- [easybashgui](https://github.com/BashGui/easybashgui)
- [yad](https://github.com/v1cont/yad)
- [fzf](https://github.com/junegunn/fzf)
- [quickemu](https://github.com/quickemu-project/quickemu)
- Special thanks to all members of **LINUX** community

![Alt](https://repobeats.axiom.co/api/embed/a2ddede7bf2c42e7c6cc92602c461ea8c86fd9f2.svg "Repobeats analytics image")

## quickemu Introduction

<div align="center">
<img src="https://dh.osowoso.org/logo.png" alt="Quickemu" width="256" />

# Quickemu

**Quickly create and run optimised Windows, macOS and Linux virtual machines:**

**Made with 💝 for <img src="https://dh.osowoso.org/tux.png" align="middle" width="24" alt="Tux (Linux)"/> & <img src="https://dh.osowoso.org/apple.png" align="middle" width="24" alt="Apple (macOS)"/>**
</div>

<p align="center">
  &nbsp;<a href="https://wimpysworld.io/discord" target="_blank"><img alt="Discord" src="https://img.shields.io/discord/712850672223125565?style=for-the-badge&logo=discord&logoColor=%23ffffff&label=Discord&labelColor=%234253e8&color=%23e4e2e2"></a>&nbsp;
  &nbsp;<a href="https://fosstodon.org/@wimpy" target="_blank"><img alt="Mastodon" src="https://img.shields.io/badge/Mastodon-6468fa?style=for-the-badge&logo=mastodon&logoColor=%23ffffff"></a>&nbsp;
  &nbsp;<a href="https://twitter.com/m_wimpress" target="_blank"><img alt="Twitter" src="https://img.shields.io/badge/Twitter-303030?style=for-the-badge&logo=x&logoColor=%23ffffff"></a>&nbsp;
  &nbsp;<a href="https://linkedin.com/in/martinwimpress" target="_blank"><img alt="LinkedIn" src="https://img.shields.io/badge/LinkedIn-1667be?style=for-the-badge&logo=linkedin&logoColor=%23ffffff"></a>&nbsp;
</p>


# Introduction

**Quickemu** is a wrapper for the excellent [QEMU](https://www.qemu.org/) that
automatically *"does the right thing"* when creating virtual machines. No
requirement for exhaustive configuration options. You decide what operating
system you want to run and Quickemu takes care of the rest 🤖

- `quickget` **automatically downloads the upstream OS** and creates the configuration 📀
- `quickemu` enumerates your hardware and launches the virtual machine with the **optimum configuration best suited to your computer** ⚡️

The original objective of the project was to [enable quick testing of Linux
distributions](https://github.com/quickemu-project/quickemu/wiki/02-Create-Linux-virtual-machines)
where the virtual machines and their configuration can be stored anywhere (such
as external USB storage or your home directory) and no elevated permissions are
required to run the virtual machines.

**Today, Quickemu includes comprehensive support for [macOS](https://github.com/quickemu-project/quickemu/wiki/03-Create-macOS-virtual-machines),
[Windows](https://github.com/quickemu-project/quickemu/wiki/04-Create-Windows-virtual-machines)**, most of the BSDs, novel non-Linux operating systems such as FreeDOS, Haiku, KolibriOS, OpenIndiana, ReactOS, and more.

# Features

- Host support for **Linux and macOS**
- **macOS** Sonoma, Ventura, Monterey, Big Sur, Catalina & Mojave
- **Windows** 10 and 11 including TPM 2.0
- **Windows Server** 2022 2019 2016
- [Ubuntu](https://ubuntu.com/desktop) and all the **[official Ubuntu
  flavours](https://ubuntu.com/download/flavours)**
- **Nearly 1000 operating system editions are supported!**
- Full SPICE support including host/guest clipboard sharing
- VirtIO-webdavd file sharing for Linux and Windows guests
- VirtIO-9p file sharing for Linux and macOS guests
- [QEMU Guest Agent
  support](https://wiki.qemu.org/Features/GuestAgent); provides access
  to a system-level agent via standard QMP commands
- Samba file sharing for Linux, macOS and Windows guests (*if `smbd`
  is installed on the host*)
- VirGL acceleration
- USB device pass-through
- Smartcard pass-through
- Automatic SSH port forwarding to guests
- Network port forwarding
- Full duplex audio
- Braille support
- EFI (with or without SecureBoot) and Legacy BIOS boot

## As featured on [Linux Matters](https://linuxmatters.sh) podcast!

The presenters of Linux Matters 🐧🎙️ are the creators of each of the principal Quickemu projects. We discussed Quickemu's 2024 reboot in [Episode 30 - Quickemu Rising From the Bashes](https://linuxmatters.sh/30). <!-- and in [Episode 32 - Quick, quicker, quickest](https://linuxmatters.sh/32) [Martin](https://github.com/flexiondotorg) unveils macOS host support for [**Quickemu**](https://github.com/quickemu-project/quickemu), [Mark](https://github.com/marxjohnson) explains the origins of the [**Quickgui**](https://github.com/quickemu-project/quickgui) desktop app and upcoming improvements, and [Alan](https://github.com/popey) debuts [**Quicktest**](https://github.com/quickemu-project/quicktest); a framework for automatically testing operating systems via Quickemu -->

<div align="center">
  <a href="https://linuxmatters.sh" target="_blank"><img src="https://github.com/wimpysworld/nix-config/raw/main/.github/screenshots/linuxmatters.png" alt="Linux Matters Podcast"/></a>
  <br />
  <em>Linux Matters Podcast</em>
</div>

# Quick start

[Once Quickemu is installed](https://github.com/quickemu-project/quickemu/wiki/01-Installation), there are two simple steps to create and run a virtual machine:

- `quickget` automatically downloads the ISO image for the operating system you want to run and creates a configuration file for the virtual machine.

``` shell
quickget nixos unstable minimal
```

- `quickemu` starts the virtual machine using the configuration file created by `quickget`.

``` shell
quickemu --vm nixos-unstable-minimal.conf
```

Execute `quickget` (with no arguments) to see a list of all the supported operating systems.

## Demo

<div align="center">

<a href="https://asciinema.org/a/658148?autoplay=1" target="_blank"><img src="https://asciinema.org/a/658148.svg" /></a>

</div>

# Documentation

The wiki describes how to get up and running with Quickemu and also covers more advanced configuration and usage.

- [**Installation**](https://github.com/quickemu-project/quickemu/wiki/01-Installation) 💾
- [**Create Linux virtual machines**](https://github.com/quickemu-project/quickemu/wiki/02-Create-Linux-virtual-machines) 🐧
- [**Create macOS virtual machines**](https://github.com/quickemu-project/quickemu/wiki/03-Create-macOS-virtual-machines) 🍏
- [**Create Windows virtual machines**](https://github.com/quickemu-project/quickemu/wiki/04-Create-Windows-virtual-machines) 🪟
- [**Advanced quickemu configuration**](https://github.com/quickemu-project/quickemu/wiki/05-Advanced-quickemu-configuration) 🔧
- [**Advanced quickget features**](https://github.com/quickemu-project/quickemu/wiki/06-Advanced-quickget-features) 🤓
- [**Alternative frontends**](https://github.com/quickemu-project/quickemu/wiki/07-Alternative-frontends) 🧑‍💻
- [**References**](https://github.com/quickemu-project/quickemu/wiki/08-References) 📚️
