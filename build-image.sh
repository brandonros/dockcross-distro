#!/bin/bash
set -e
# update sources
apt-get update
# install dependencies
DEBIAN_FRONTEND=noninteractive apt-get install -y curl unzip qemu-utils parted udev extlinux kpartx
# download kernel artifact
cd /root
curl -o artifact.zip -L "$DOCKCROSS_KERNEL_BUILD_ARTIFACT_URL"
unzip artifact.zip
rm artifact.zip
# make raw image
qemu-img create -f raw $IMG_RAW $SIZE
# partition raw image
parted -s $IMG_RAW mklabel msdos
parted -s -a none $IMG_RAW mkpart primary ext4 0 $SIZE
parted -s -a none $IMG_RAW set 1 boot on
# install MBR
dd if=/usr/lib/syslinux/mbr/mbr.bin of=$IMG_RAW conv=notrunc bs=440 count=1
# format filesystem
kpartx -av $IMG_RAW
mke2fs -t ext4 /dev/mapper/loop0p1
# mount filesystem
mount /dev/mapper/loop0p1 /mnt
# install extlinux
mkdir /mnt/boot
extlinux --install /mnt/boot
cat > /mnt/boot/extlinux.conf <<EOF
default linux
prompt 1
timeout 50
LABEL linux
    MENU Linux
    LINUX /boot/bzImage
    APPEND rw root=/dev/sda1
EOF
# copy kernel files
cp /root/bzImage /mnt/boot
cp /root/.config /mnt/boot
# download busybox
mkdir /mnt/bin
curl -o /mnt/bin/busybox $BUSYBOX_BINARY_URL
chmod +x /mnt/bin/busybox
# install busybox
mkdir /mnt/sbin
mkdir /mnt/usr
mkdir /mnt/usr/bin
mkdir /mnt/usr/sbin
chroot /mnt /bin/busybox sh -c "/bin/busybox --install"
# create device nodes
mkdir /mnt/dev
mknod -m 600 /mnt/dev/console c 5 1
mknod -m 666 /mnt/dev/null c 1 3
# create mount directories
mkdir /mnt/proc
mkdir /mnt/sys
# create fstab
mkdir /mnt/etc
cat > /mnt/etc/fstab <<EOF
proc /proc proc nosuid,noexec,nodev 0 0
sysfs /sys sysfs nosuid,noexec,nodev 0 0
EOF
# create init script
cat > /etc/init.d/rcS <<EOF
#/bin/sh
mount -a
EOF
# unmount
umount /mnt
# convert to qcow2
qemu-img convert -f raw -O qcow2 $IMG_RAW $IMG_QCOW2
rm $IMG_RAW
# copy image
cp $IMG_QCOW2 /output
# finish
exit
