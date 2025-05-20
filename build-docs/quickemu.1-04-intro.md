
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
