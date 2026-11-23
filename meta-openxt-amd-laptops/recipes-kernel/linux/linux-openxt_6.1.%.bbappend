FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

# Kernel configuration fragments, merged on top of the per-machine defconfig
# from xenclient-oe.
OPENXT_KERNEL_FRAGMENTS ?= ""
OPENXT_KERNEL_FRAGMENTS_xenclient-dom0 = "dom0-amd-laptops.cfg"
OPENXT_KERNEL_FRAGMENTS_xenclient-ndvm = "ndvm-amd-laptops.cfg"
OPENXT_KERNEL_FRAGMENTS_openxt-installer = "installer-amd-laptops.cfg"

SRC_URI += "${@' '.join('file://' + f for f in d.getVar('OPENXT_KERNEL_FRAGMENTS').split())}"

# NDVM: let ath11k (Qualcomm WCN6855 Wi-Fi, ThinkPad Z13) use the host's MSI
# address/data under PCI passthrough. See the patch and ath11k-xen-msi in
# recipes-openxt.
SRC_URI_append_xenclient-ndvm = " file://0001-wifi-ath11k-pci-allow-host-MSI-address-data-for-pass.patch"

# A postfunc rather than do_configure_append: kernel-module-signing.bbclass
# appends code that returns early from do_configure when module signing is
# disabled, which would skip anything appended after it.
do_configure[postfuncs] += "openxt_kernel_merge_fragments"

openxt_kernel_merge_fragments() {
    if [ -z "${OPENXT_KERNEL_FRAGMENTS}" ]; then
        return
    fi

    for frag in ${OPENXT_KERNEL_FRAGMENTS}; do
        cat "${WORKDIR}/${frag}" >> "${B}/.config"
    done

    oe_runmake -C ${S} O=${B} olddefconfig

    # Kconfig silently drops options whose dependencies are not met.
    # Fail the build instead of producing a kernel without the driver.
    for frag in ${OPENXT_KERNEL_FRAGMENTS}; do
        grep -E '^CONFIG_[A-Za-z0-9_]+=' "${WORKDIR}/${frag}" > "${WORKDIR}/${frag}.wanted"
        while read -r line; do
            if ! grep -qxF "${line}" "${B}/.config"; then
                bbfatal "${frag}: '${line}' did not survive olddefconfig (unmet dependency?)"
            fi
        done < "${WORKDIR}/${frag}.wanted"
    done
}
