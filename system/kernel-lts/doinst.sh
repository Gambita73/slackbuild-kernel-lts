KVER=@KVER@

# Stable names for the bootloader: /boot/vmlinuz-lts always points at the
# newest kernel-lts, the same way /boot/vmlinuz-generic does for the stock one.
( cd boot || exit ; rm -f vmlinuz-lts ; ln -sf vmlinuz-lts-$KVER vmlinuz-lts )
( cd boot || exit ; rm -f System.map-lts ; ln -sf System.map-lts-$KVER System.map-lts )
( cd boot || exit ; rm -f config-lts ; ln -sf config-lts-$KVER config-lts )

# Refresh the module index when installing to the running system.
if [ -x /sbin/depmod ] && [ "$(pwd)" = "/" ]; then
  /sbin/depmod -a $KVER 1> /dev/null 2> /dev/null
fi

cat << EOF

kernel-lts $KVER is installed next to your stock kernel. It will not boot
until you make an initrd for it and add it to your bootloader:

  /usr/share/mkinitrd/mkinitrd_command_generator.sh -k $KVER \\
      -a "-o /boot/initrd-lts.gz" | bash

Then see /usr/doc/kernel-lts-*/README.SLACKWARE for lilo, elilo and GRUB.

EOF
