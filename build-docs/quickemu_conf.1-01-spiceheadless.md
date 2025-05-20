## Connecting to your VM

### SPICE

The following features are available while using the SPICE protocol:

- Copy/paste between the guest and host
- Host file sharing with the guest
- USB device redirection

To use SPICE add `--display spice` to the Quickemu invocation, this
requires that the `spicy` client is installed, available from the
`spice-client-gtk` package in Debian/Ubuntu.

``` shell
quickemu --vm ubuntu-22.04.conf --display spice
```

To enable copy/paste with a Windows guest, install [SPICE Windows guest
tools](https://www.spice-space.org/download.html) in the guest VM.

### Headless

To start a VM with SPICE enabled, but no display attached use
`--display none`. This requires that the `spicy` client is installed,
available from the `spice-client-gtk` package in Debian/Ubuntu to
connect to the running VM

``` shell
quickemu --vm ubuntu-22.04.conf --display none
```

You can also use the `.ports` file in the VM directory to lookup what
SSH and SPICE ports the VM is connected to.

``` shell
cat ubuntu-22.04/ubuntu-22.04.ports
```

If, for example, the SSH port is set to 22220, and assuming your VM has
a started SSH service (details vary by OS), you can typically SSH into
it from the host as follows:

``` shell
ssh -p 22220 your_vm_user@localhost
```
