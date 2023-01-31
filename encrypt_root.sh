#!/bin/bash


#set -e
set -x

# Create an empty image as below and mount them
# ----------------------------------------------
# | boot(vfat) | rootfs(ext4) |
# ----------------------------------------------
rm -f image.img
dd if=/dev/zero of=image.img bs=1M count=1024
LOOP_DEV=$(losetup -f)
losetup $LOOP_DEV image.img

# partitioning
parted -a optimal $LOOP_DEV -s mklabel msdos \
  -s mkpart primary fat32 2048s   100MiB \
  -s mkpart primary ext4  100MiB  900MiB
fdisk -l ${LOOP_DEV}

# setup crypt parition
cryptsetup -y -v --key-size=512 luksFormat ${LOOP_DEV}p1
cryptsetup -y -v --key-size=512 luksFormat ${LOOP_DEV}p2

dd bs=512 count=4 if=/dev/urandom of=./luks_keyfile
cryptsetup luksAddKey ${LOOP_DEV}p1 ./luks_keyfile
cryptsetup luksAddKey ${LOOP_DEV}p2 ./luks_keyfile
cryptsetup luksDump ${LOOP_DEV}p1
cryptsetup luksDump ${LOOP_DEV}p2

# mapping partition
cryptsetup open ${LOOP_DEV}p1 cryptboot
cryptsetup open ${LOOP_DEV}p2 cryptroot
ls /dev/mapper

mkfs.vfat  /dev/mapper/cryptboot
mkfs.ext4  /dev/mapper/cryptroot
mkdir fs fs/boot fs/rootfs
mount ${LOOP_DEV}p1 fs/boot
mount ${LOOP_DEV}p2 fs/rootfs
