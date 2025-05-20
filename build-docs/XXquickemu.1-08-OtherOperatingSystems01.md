You can also use `quickget` with advanced options :

<!-- [[[cog
import subprocess

import cog
# cannot use check_result() because of non-zero return
result=subprocess.run(["./get_quickget_help"], capture_output=True, text=True)
help=result.stdout
cog.out(f"\n``` text\n{help}\n```\n")
]]] -->

The output goes here

<!-- [[[end]]] -->


Here are some typical uses

``` shell
    # show an OS ISO download URL for {os} {release} [edition]
    quickget --url fedora 38 Silverblue
    # test if an OS ISO is available for {os} {release} [edition]
    quickget --check nixos unstable plasma5
    # open an OS distribution homepage in a browser
    quickget --open-homepage  ubuntu-mate
    # Only download image file into current directory, without creating VM
    quickget --download elementary 7.1
```

The `--url`, `--check`, and `--download` options are fully
functional for all operating systems, including Windows and macOS.

Further information is available from the project [wiki](https://github.com/quickemu-project/quickemu/wiki/06-Advanced-quickget-features)

### Other Operating Systems

`quickget` also supports:
