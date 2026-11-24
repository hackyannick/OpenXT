SUMMARY = "Host MSI values for Qualcomm ath11k Wi-Fi in the OpenXT network VM"
DESCRIPTION = "dom0 tool and boot service that read the real MSI address/data \
of an ath11k Wi-Fi device (e.g. WCN6855 in the ThinkPad Z13 Gen1) and store \
them in the network VM's domstore, where the network VM's init script picks \
them up as ath11k_pci module parameters."
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-2.0;md5=801f80980d171dd6425610833a22dbe6"

SRC_URI = " \
    file://ath11k-xen-msi \
    file://ath11k-xen-msi.initscript \
"

S = "${WORKDIR}"

inherit allarch update-rc.d

# Runlevel 5 only: the network VM is started automatically only by the
# normal boot entry ("autostart"), not in the support console (runlevel 3).
# After xenmgr (S80), which starts the network VM.
INITSCRIPT_NAME = "ath11k-xen-msi"
INITSCRIPT_PARAMS = "start 85 5 ."

do_install() {
    install -d ${D}${sbindir} ${D}${sysconfdir}/init.d
    install -m 0755 ${WORKDIR}/ath11k-xen-msi ${D}${sbindir}/ath11k-xen-msi
    install -m 0755 ${WORKDIR}/ath11k-xen-msi.initscript ${D}${sysconfdir}/init.d/ath11k-xen-msi
}

RDEPENDS_${PN} = "bash coreutils dbd-tools xec"
