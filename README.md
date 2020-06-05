# dockcross-distro
Build a .qcow2 VM image from a dockcross-kernel build

## Usage

### Build disk.qcow2

`./compile.sh`

### Boot disk.qcow2

`qemu-system-x86_64 -m 1024 -hda disk.qcow2`
