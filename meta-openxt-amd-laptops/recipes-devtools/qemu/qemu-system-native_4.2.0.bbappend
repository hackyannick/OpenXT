# qemu-img (from qemu-system-native) converts the OpenXT VM images to VHD and
# the OVMF images to qcow2. Under Rosetta 2 (x86_64 build container on Apple
# Silicon) it died with "rosetta error: Unimplemented syscall number 282"
# because QEMU 4.2 calls the legacy signalfd syscall directly.
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI += "file://0001-util-compatfd-use-libc-signalfd-wrapper.patch"
