#!/bin/sh

MOUNT_DIR=/tmp/ext2img
DISK_IMG=floppy.img
KERNEL_IMG=kernel

mkdir $MOUNT_DIR
mount $DISK_IMG $MOUNT_DIR
cp $KERNEL_IMG $MOUNT_DIR
umount $MOUNT_DIR
rm -rf $MOUNT_DIR
