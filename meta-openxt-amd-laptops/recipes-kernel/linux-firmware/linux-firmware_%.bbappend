# oe-core (dunfell) ships the amdgpu, amd-ucode and Cirrus blobs only in the
# catch-all linux-firmware package. Split out what the supported laptops need:
#  - HP EliteBook 845 G7: Renoir iGPU, Family 17h microcode
#  - Lenovo ThinkPad Z13 Gen1: Yellow Carp (Rembrandt) iGPU, Family 19h
#    microcode, CS35L41 speaker amplifier tunings (subsystem 17aa22f1/22f2)

PACKAGES =+ " \
    ${PN}-amdgpu-license ${PN}-amdgpu-renoir ${PN}-amdgpu-yellow-carp \
    ${PN}-amd-ucode-license ${PN}-amd-ucode \
    ${PN}-cirrus-license ${PN}-cirrus-cs35l41 \
"

LICENSE_${PN}-amdgpu-license = "Firmware-amdgpu"
LICENSE_${PN}-amdgpu-renoir = "Firmware-amdgpu"
LICENSE_${PN}-amdgpu-yellow-carp = "Firmware-amdgpu"
FILES_${PN}-amdgpu-license = "${nonarch_base_libdir}/firmware/LICENSE.amdgpu"
FILES_${PN}-amdgpu-renoir = "${nonarch_base_libdir}/firmware/amdgpu/renoir_*"
FILES_${PN}-amdgpu-yellow-carp = "${nonarch_base_libdir}/firmware/amdgpu/yellow_carp_*"
RDEPENDS_${PN}-amdgpu-renoir += "${PN}-amdgpu-license"
RDEPENDS_${PN}-amdgpu-yellow-carp += "${PN}-amdgpu-license"

# Xen loads CPU microcode itself. xen.efi reads it from the ESP, and the
# installer copies /boot/*.bin from dom0 to the ESP. Xen walks every
# container in the blob and picks the one matching the CPU, so one file can
# serve both Family 17h (Renoir) and Family 19h (Rembrandt).
LICENSE_${PN}-amd-ucode-license = "Firmware-amd-ucode"
LICENSE_${PN}-amd-ucode = "Firmware-amd-ucode"
FILES_${PN}-amd-ucode-license = "${nonarch_base_libdir}/firmware/LICENSE.amd-ucode"
FILES_${PN}-amd-ucode = " \
    ${nonarch_base_libdir}/firmware/amd-ucode \
    /boot/microcode_amd.bin \
"
RDEPENDS_${PN}-amd-ucode += "${PN}-amd-ucode-license"

# LICENSE.cirrus is installed by the recipe but not declared in it.
LICENSE_append = " & Firmware-cirrus"
LIC_FILES_CHKSUM_append = " file://LICENSE.cirrus;md5=662ea2c1a8888f7d79ed7f27c27472e1"
NO_GENERIC_LICENSE[Firmware-cirrus] = "LICENSE.cirrus"
LICENSE_${PN}-cirrus-license = "Firmware-cirrus"
LICENSE_${PN}-cirrus-cs35l41 = "Firmware-cirrus"
FILES_${PN}-cirrus-license = "${nonarch_base_libdir}/firmware/LICENSE.cirrus"
FILES_${PN}-cirrus-cs35l41 = "${nonarch_base_libdir}/firmware/cirrus/cs35l41*"
RDEPENDS_${PN}-cirrus-cs35l41 += "${PN}-cirrus-license"

do_install_append() {
    install -d ${D}/boot
    cat ${D}${nonarch_base_libdir}/firmware/amd-ucode/microcode_amd_fam17h.bin \
        ${D}${nonarch_base_libdir}/firmware/amd-ucode/microcode_amd_fam19h.bin \
        > ${D}/boot/microcode_amd.bin
    chmod 0644 ${D}/boot/microcode_amd.bin
}
