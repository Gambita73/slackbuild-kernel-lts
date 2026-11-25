# Linux 6.1 LTS for Slackware 15.0

Slackware 15.0 ships the 5.15 kernel, which kernel.org will stop supporting in
December 2026. Linux 6.1 is a longterm branch that kernel.org projects to
support until December 2027. This repository holds a SlackBuild that builds a
6.1.y kernel from Slackware's own 5.15 config, laid out so that **sbopkg** can
use it as a repository.

The package installs **next to** the stock kernel (/boot/vmlinuz-lts-<ver>,
/lib/modules/<ver>) and never touches kernel-generic, kernel-modules or
kernel-headers, so the stock 5.15 kernel stays available as a fallback.

```
kernel-lts.repo                     sbopkg repository descriptor
bump-version.sh                     moves the SlackBuild to a new 6.1.y
system/kernel-lts/                  the SlackBuild (SBo layout)
.github/workflows/bump.yml runs bump-version.sh daily on GitHub
(**Note**: I will test if the kernel builds and works properly after updates.)
```

## Using it with sbopkg

```sh
# 1. Register the repository (once)
wget -O /etc/sbopkg/repos.d/70-kernel-lts.repo \
  https://raw.githubusercontent.com/Gambita73/slackbuild-kernel-lts/main/kernel-lts.repo

# 2. Sync it and build/install the kernel
sbopkg -V kernel-lts/15.0 -r
sbopkg -V kernel-lts/15.0 -i kernel-lts
(Trick: alias sbolts='sbopkg -V kernel-lts/15.0')

# 3. Make an initrd for it (replace 6.1.x with the installed version)
/usr/share/mkinitrd/mkinitrd_command_generator.sh -k 6.1.x \
    -a "-o /boot/initrd-lts.gz" | bash
```

Then add /boot/vmlinuz-lts with /boot/initrd-lts.gz to lilo, elilo or GRUB.
`system/kernel-lts/README` has the exact entries for each bootloader.

You can also pick the repository from sbopkg's menu under **Repository**.
sbopkg -V kernel-lts/15.0 -c lists available updates for the kernel.

**After every upgrade**, rebuild /boot/initrd-lts.gz with the new version
and rerun lilo (or copy the files to the EFI partition for elilo, or rerun
grub-mkconfig). The initrd holds modules for one exact kernel version.

### Build options

Set these in the environment, for example
SOURCE=yes sbopkg -V kernel-lts/15.0 -i kernel-lts:

| Variable | Default | Effect |
|---|---|---|
| `CONFIG` | newest `/boot/config-generic-5.15.*`, then `/proc/config.gz` | Starting config |
| `SOURCE` | `no` | `yes` also packages the source tree in `/usr/src/linux-lts-<ver>` so out-of-tree modules (nvidia-kernel, VirtualBox) can build. Adds about 1.2 GB. |
| `DEBUG` | `no` | `yes` keeps debug info/BTF from the config |
| `JOBS` | number of CPUs | Parallel make jobs |

A build takes from 30 minutes to several hours and needs about 8 GB free in
/tmp/SBo.
