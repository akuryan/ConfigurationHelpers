#!/bin/bash

#this script will mount datadisk to a folder datadrive

dmesg | grep SCSI
read -p "Enter disk name please:" diskname
echo "You've selected disk drive $diskname"
echo "Select p, followed by w"
fdisk /dev/$diskname
read -p "Enter disk device name please:" diskDevice
echo "You've selected disk device $diskDevice"
mkfs -t ext4 /dev/$diskDevice
fs_uuid=$(blkid -o value -s UUID /dev/$diskDevice)
mkdir /datadrive
mount /dev/$diskDevice /datadrive

echo "UUID=$fs_uuid   /datadrive   ext4   defaults,nofail   1   2" >> /etc/fstab

