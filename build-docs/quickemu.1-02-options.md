# OPTIONS

**\-\-vm**
: vm configuration file

You can also pass optional parameters

**\-\-access**  
  : Enable remote spice access support. 'local' (default), 'remote', 'clientipaddress'

**\-\-braille**  
  : Enable braille support. Requires SDL.

**\-\-delete-disk**  
  : Delete the disk image and EFI variables

**\-\-delete-vm**  
  : Delete the entire VM and its configuration

**\-\-display**  
  : Select display backend. 'sdl' (default), 'gtk', 'none', 'spice' or 'spice-app'

**\-\-fullscreen**  
  : Starts VM in full screen mode (Ctl+Alt+f to exit)

**\-\-ignore-msrs-always**  
  : Configure KVM to always ignore unhandled machine-specific registers

**\-\-kill**
  : Kill the VM process if it is running

**\-\-offline**
  : Override all network settings and start the VM offline

**\-\-shortcut**  
: Create a desktop shortcut

**\-\-snapshot apply \<tag\>**  
: Apply/restore a snapshot.

**\-\-snapshot create \<tag\>**  
: Create a snapshot.

**\-\-snapshot delete \<tag\>**  
: Delete a snapshot.

**\-\-snapshot info**  
: Show disk/snapshot info.

**\-\-status-quo**  
: Do not commit any changes to disk/snapshot.

**\-\-viewer \<viewer\>**  
: Choose an alternative viewer. @Options: 'spicy' (default), 'remote-viewer', 'none'

**\-\-width \<width\>**  
: Set VM screen width; requires '\-\-height'

**\-\-height \<height\>**  
: Set VM screen height; requires '\-\-width'

**\-\-ssh-port \<port\>**  
: Set SSH port manually

**\-\-spice-port \<port\>**  
: Set SPICE port manually

**\-\-public-dir \<path\>**  
: Expose share directory. @Options: '' (default: xdg-user-dir PUBLICSHARE), '<directory>', 'none'

**\-\-monitor \<type\>**  
: Set monitor connection type. @Options: 'socket' (default), 'telnet', 'none'

**\-\-monitor-telnet-host \<ip/host\>**  
: Set telnet host for monitor. (default: 'localhost')

**\-\-monitor-telnet-port \<port\>**  
: Set telnet port for monitor. (default: '4440')

**\-\-monitor-cmd \<cmd\>**  
: Send command to monitor if available. (Example: system_powerdown)

**\-\-serial \<type\>**  
: Set serial connection type. @Options: 'socket' (default), 'telnet', 'none'

**\-\-serial-telnet-host \<ip/host\>**  
: Set telnet host for serial. (default: 'localhost')

**\-\-serial-telnet-port \<port\>**  
: Set telnet port for serial. (default: '6660')

**\-\-keyboard \<type\>**  
: Set keyboard. @Options: 'usb' (default), 'ps2', 'virtio'

**\-\-keyboard_layout \<layout\>**  
: Set keyboard layout: 'en-us' (default)

**\-\-mouse \<type\>**  
: Set mouse. @Options: 'tablet' (default), 'ps2', 'usb', 'virtio'

**\-\-usb-controller \<type\>**  
: Set usb-controller. @Options: 'ehci' (default), 'xhci', 'none'

**\-\-sound-card \<type\>**  
: Set sound card. @Options: 'intel-hda' (default), 'ac97', 'es1370', 'sb16', 'none'

**\-\-extra_args \<arguments\>**  
: Pass additional arguments to qemu

**\-\-version**  
:    Print version
