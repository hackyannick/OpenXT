FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI += "file://rtw88.conf"

do_install_append() {
    install -m 0644 ${WORKDIR}/rtw88.conf ${D}/etc/modprobe.d/rtw88.conf
}
