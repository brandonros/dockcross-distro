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
# mount raw image as filesystem
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
# create root home
mkdir /mnt/root
# create fstab
mkdir /mnt/etc
cat > /mnt/etc/fstab <<EOF
proc /proc proc nosuid,noexec,nodev 0 0
sysfs /sys sysfs nosuid,noexec,nodev 0 0
EOF
# create init script
mkdir /mnt/etc/init.d
cat > /mnt/etc/init.d/rcS <<EOF
#!/bin/sh
/bin/mount -a
/sbin/ifconfig lo 127.0.0.1 netmask 255.0.0.0
/sbin/ifconfig eth0 up
/sbin/ifconfig eth0 10.0.2.15
/sbin/route add default gw 10.0.2.2
EOF
chmod +x /mnt/etc/init.d/rcS
# create passwd file
cat > /mnt/etc/passwd <<EOF
root:x:0:0:root:/root:/bin/bash
EOF
# create group file
cat > /mnt/etc/group <<EOF
root:x:0:
bin:x:1:
sys:x:2:
kmem:x:3:
tty:x:4:
tape:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
usb:x:14:
EOF
# create resolv file
cat > /mnt/etc/resolv.conf <<EOF
nameserver 8.8.8.8
EOF
# unmount raw image
umount /mnt
# convert to qcow2
qemu-img convert -f raw -O qcow2 $IMG_RAW $IMG_QCOW2
rm $IMG_RAW
# copy image
cp $IMG_QCOW2 /output
# finish
exit
