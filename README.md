# dockcross-distro
Build a .qcow2 VM image from a dockcross-kernel build

## Usage

### Build disk.qcow2

```shell
cat build-image.sh | docker \
  run \
  -i \
  --privileged \
  -e DOCKCROSS_KERNEL_BUILD_ARTIFACT_URL="https://github.com/brandonros/dockcross-kernel/releases/download/v5.7/artifact.zip" \
  -e BUSYBOX_BINARY_URL="https://www.busybox.net/downloads/binaries/1.31.0-defconfig-multiarch-musl/busybox-x86_64" \
  -e IMG_RAW=/root/disk.raw \
  -e IMG_QCOW2=/root/disk.qcow2 \
  -e SIZE=10G \
  -v $(pwd):/output \
  ubuntu
```

### Boot disk.qcow2

2. `qemu-system-x86_64 -m 1024 -hda disk.qcow2`
