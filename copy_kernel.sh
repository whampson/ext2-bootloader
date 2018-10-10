#!/bin/sh

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Copyright (C) 2018 Wes Hampson. All Rights Reserved.                         #
#                                                                              #
# This is free software: you can redistribute it and/or modify                 #
# it under the terms of version 2 of the GNU General Public License            #
# as published by the Free Software Foundation.                                #
#                                                                              #
# See LICENSE in the top-level directory for a copy of the license.            #
# You may also visit <https://www.gnu.org/licenses/gpl-2.0.txt>.               #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

#-------------------------------------------------------------------------------
#   File: copy_kernel.sh
# Author: Wes Hampson
#------------------------------------------------------------------------------#

MOUNT_DIR=/tmp/ext2img
DISK_IMG=floppy.img
KERNEL_IMG=kernel

mkdir $MOUNT_DIR
mount $DISK_IMG $MOUNT_DIR
cp $KERNEL_IMG $MOUNT_DIR
umount $MOUNT_DIR
rm -rf $MOUNT_DIR
