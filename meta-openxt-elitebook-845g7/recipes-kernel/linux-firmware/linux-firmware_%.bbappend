# oe-core (dunfell) ships the amdgpu and amd-ucode blobs only in the
# catch-all linux-firmware package. Split out what the EliteBook 845 G7 needs.

PACKAGES =+ " \
    ${PN}-amdgpu-license ${PN}-amdgpu-renoir \
    ${PN}-amd-ucode-license ${PN}-amd-ucode \
"

LICENSE_${PN}-amdgpu-license = "Firmware-amdgpu"
LICENSE_${PN}-amdgpu-renoir = "Firmware-amdgpu"
FILES_${PN}-amdgpu-license = "${nonarch_base_libdir}/firmware/LICENSE.amdgpu"
FILES_${PN}-amdgpu-renoir = "${nonarch_base_libdir}/firmware/amdgpu/renoir_*"
RDEPENDS_${PN}-amdgpu-renoir += "${PN}-amdgpu-license"

# Xen loads CPU microcode itself. xen.efi reads it from the ESP, and the
# installer copies /boot/*.bin from dom0 to the ESP.
LICENSE_${PN}-amd-ucode-license = "Firmware-amd-ucode"
LICENSE_${PN}-amd-ucode = "Firmware-amd-ucode"
FILES_${PN}-amd-ucode-license = "${nonarch_base_libdir}/firmware/LICENSE.amd-ucode"
FILES_${PN}-amd-ucode = " \
    ${nonarch_base_libdir}/firmware/amd-ucode \
    /boot/microcode_amd_fam17h.bin \
"
RDEPENDS_${PN}-amd-ucode += "${PN}-amd-ucode-license"

do_install_append() {
    install -d ${D}/boot
    install -m 0644 ${D}${nonarch_base_libdir}/firmware/amd-ucode/microcode_amd_fam17h.bin \
        ${D}/boot/microcode_amd_fam17h.bin
}
