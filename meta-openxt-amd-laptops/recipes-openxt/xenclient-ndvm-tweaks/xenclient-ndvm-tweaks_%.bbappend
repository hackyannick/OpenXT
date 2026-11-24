FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI += " \
    file://rtw88.conf \
    file://ath11k-xen.conf \
    file://ath11k-xen-msi.initscript \
"

# ath11k (Qualcomm WCN6855, ThinkPad Z13): loaded by the init script with
# the host MSI values from dom0 instead of by udev. dom0 side:
# recipes-openxt/ath11k-xen-msi.
inherit update-rc.d
INITSCRIPT_NAME = "ath11k-xen-msi"
INITSCRIPT_PARAMS = "defaults 40"
RDEPENDS_${PN} += "dbd-tools-vm"

do_install_append() {
    install -m 0644 ${WORKDIR}/rtw88.conf ${D}/etc/modprobe.d/rtw88.conf
    install -m 0644 ${WORKDIR}/ath11k-xen.conf ${D}/etc/modprobe.d/ath11k-xen.conf
    install -d ${D}${sysconfdir}/init.d
    install -m 0755 ${WORKDIR}/ath11k-xen-msi.initscript ${D}${sysconfdir}/init.d/ath11k-xen-msi
}
