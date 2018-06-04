#!/usr/bin/env bash

# file: setup_drive_mbr.sh
# This file is a script for creating a virtual image of a block
# device for sharing files through the g_mass_storage drive of
# the raspbians. The following environment variables can be used
# for customizing the file:
#
# TARGET_DEVICE: path of the device to be created including name,
#                its default value is `/piusb.bin`
# BLOCK_SIZE: block size of the virtual drive.
#             Its default value is set to 512, the fat's default value
# DEVICE_SIZE: The size of the device to be created. This has to have the
#              format of the `dd`` argument `seek``.
#              Its default value is 1024*1024*2 for a total of
#              BLOCK_SIZE x DECIVE_SIZE = 1G
#
# - Usage example:
#
# Create a /piusb.bin file of 1GiB
#
# # ./setup_drive_mbr.sh
#
# Create a local.bin file of 512MiB
#
# # TARGET_DEVICE=./local.bin BLOCK_SIZE=512 DEVICE_SIZE=$[1024*1024] ./setup_drive_mbr.sh
#
# The created file will have a partition table of 1 Master Record and
# 1 volume record of the full size of the disk with a exFAT partition.

# name of the file system storage image, if the script was
# invoked with a first argument, such will be the target device
# otherwise its set to a default name/path
if [ -z $TARGET_DEVICE ]; then
    echo "Using default path value of /piusb.bin"
    TARGET_DEVICE=/piusb.bin
fi
# if the file exist abort !
if [ -e $TARGET_DEVICE ]; then
    echo "File ${TARGET_DEVICE} exists, please remove it or select another file."
    echo "Aborting ..."
    exit 1
fi

# block size set to fat32 default
if [ -z $BLOCK_SIZE ]; then
    echo "Using default block size of 512"
    BLOCK_SIZE=512
fi
# Size of the file system storage
if [ -z $DEVICE_SIZE ]; then
    echo "Using default device size of 1G/512"
    DEVICE_SIZE=$[1024*1024*2]
fi

# Create a zero filled file for our image
sudo dd if=/dev/zero of=$TARGET_DEVICE bs=$BLOCK_SIZE count=0 seek=$DEVICE_SIZE

# Create a partition table of 1 Master Record and 1 Volume Record
# This is needed for Windows to detect the virtual device
# for more info on creating the partitions check: https://superuser.com/questions/332252/how-to-create-and-format-a-partition-using-a-bash-script?utm_medium=organic&utm_source=google_rich_qa&utm_campaign=google_rich_qa
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | sudo fdisk $TARGET_DEVICE > /dev/null
  o # clear the in memory partition table
  n # create partition
  p # primary partititon
  1 # partition number 1
    # default start
    # default end - Full disk
  t # change the type of the partition
  7 # selected partition 7 exFAT for high compatibility
  w # write changes
  q # done
EOF

# Check if loop device exists
if [ ! -e /dev/loop0 ]; then
    echo "loop devices are not setup, check if the loop module is loaded"
    echo "https://bbs.archlinux.org/viewtopic.php?pid=1428929#p1428929"
    echo "Aborting ..."
    exit 1
fi

sleep 5
# mount the disk on a loop device for formating
# use the -P switch for loading all partitions
sudo losetup -P /dev/loop0 $TARGET_DEVICE

# Check if loop device was mounted with its partitions
if [ ! -e /dev/loop0p1 ]; then
    echo "loop device wasn't loaded with its partitions"
    echo "something is wrong, aborting..."
    exit 1
fi
# format the first partition
# it must be mounted on loop0p1
sudo mkexfatfs /dev/loop0p1

sleep 5
# unmounting the device to be mounted later as g_mass_storage
sudo losetup -d /dev/loop0

