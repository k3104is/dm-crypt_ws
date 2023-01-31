#!/bin/bash

# make encrypted img
echo "### make encrypted img ###"
sudo dd if=/dev/zero of=./encrypted.img bs=1M count=32
LOOP_DEV=$(losetup -f)
sudo losetup ${LOOP_DEV} ./encrypted.img
#sudo mkfs -t ext4 -O has_journal ${LOOP_DEV}
#sudo dmsetup -v create encrypted --table "0 $(sudo blockdev --getsize ${LOOP_DEV}) crypt capi:cbc(aes)-plain :36:logon:logkey: 0 ${LOOP_DEV} 0 1 sector_size:512"
sudo dmsetup -v create encrypted --table "0 $(sudo blockdev --getsize ${LOOP_DEV}) crypt aes-cbc-essiv:sha256 babebabebabebabebabebabebabebabe 0 ${LOOP_DEV} 0"
sudo dmsetup table --showkey encrypted

# mount, write and remove
echo "### mount, write and remove ###"
sudo mkfs -t ext4 /dev/mapper/encrypted
sudo mount -t ext4 /dev/mapper/encrypted /mnt
sudo sh -c 'echo "This is a test of full disk encryption on ubuntu" > /mnt/readme.txt'
sudo umount /mnt
sudo dmsetup remove encrypted
sudo losetup -d ${LOOP_DEV}

# restart and check
echo "### restart and check ###"
sudo losetup ${LOOP_DEV} ./encrypted.img
sudo dmsetup -v create encrypted --table "0 $(sudo blockdev --getsize /dev/loop12) crypt aes-cbc-essiv:sha256 babebabebabebabebabebabebabebabe 0 /dev/loop12 0"
sudo mount -t ext4 /dev/mapper/encrypted /mnt
sudo cat /mnt/readme.txt

# clean up
echo "### clean up ###"
sudo umount /mnt
sudo dmsetup remove encrypted
sudo losetup -d ${LOOP_DEV}
sudo rm -f ./encrypted.img
