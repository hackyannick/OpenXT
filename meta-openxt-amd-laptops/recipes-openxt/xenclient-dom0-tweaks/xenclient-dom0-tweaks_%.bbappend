# Replace xenclient-oe's openxt.cfg (xen.efi configuration) with the AMD
# variant from files/. Differences to the Intel default:
#  - no TXT launch entries in [global]: Intel TXT does not exist on AMD CPUs,
#    so there is no DRTM/measured launch on this platform;
#  - AMD microcode (Family 17h + 19h) instead of the Intel blob;
#  - dom0 gets 1 GiB instead of 768 MiB (amdgpu needs more GTT memory).
# Section names are unchanged, the installer creates EFI boot entries for them.
#
# The file deliberately has no comments: openxt-measuredlaunch's
# parse_eficfg greps the raw lines for keywords.
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

# ath11k-xen-msi: stores the real MSI address/data of a Qualcomm ath11k Wi-Fi
# device for the network VM (ThinkPad Z13 Gen1, WCN6855).
SRC_URI += "file://ath11k-xen-msi"

do_install_append() {
    install -d ${D}${sbindir}
    install -m 0755 ${WORKDIR}/ath11k-xen-msi ${D}${sbindir}/ath11k-xen-msi
}
