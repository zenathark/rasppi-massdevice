#!/usr/bin/env bash

# file: mount_drive.sh
# This file is a script for mounting a multi-partititon  virtual image
# of a block device for sharing files through the g_mass_storage drive of
# the raspbians. The following environment variables can be used
# for customizing the file:
#
# TARGET_DEVICE: path of the device to be created including name,
#                its default value is `/piusb.bin`
#
# - Usage example:
#
# Mount /piusb.bin
#
# # ./mount_drive.sh
#
# Mount a local.bin
#
# # TARGET_DEVICE=./local.bin ./mount_drive.sh
#
# The created file will have a partition table of 1 Master Record and
# 1 volume record of the full size of the disk with a exFAT partition.

if [ -z $TARGET_DEVICE ]; then
    echo "Using default path value of /piusb.bin"
    TARGET_DEVICE=/piusb.bin
fi

# Check if loop device exists
if [ ! -e /dev/loop0 ]; then
    echo "loop devices are not setup, check if the loop module is loaded"
    echo "https://bbs.archlinux.org/viewtopic.php?pid=1428929#p1428929"
    echo "Aborting ..."
    exit 1
fi
# mount the disk on a loop device for formating
# use the -P switch for loading all partitions
sudo losetup -P /dev/loop0 $TARGET_DEVICE

# Check if loop device was mounted with its partitions
if [ ! -e /dev/loop0p1 ]; then
    echo "loop device wasn't loaded with its partitions"
    echo "something is wrong, aborting..."
    exit 1
fi

sudo mount /dev/loop0p1 /mnt
