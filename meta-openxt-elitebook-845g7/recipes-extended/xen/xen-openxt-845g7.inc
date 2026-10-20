# Shared by xen_git.bbappend and xen-tools_git.bbappend.
#
# xenclient-oe builds Xen from the tip of stable-4.21 (AUTOREV). Its
# kconfig-grant-table-v2-interface.patch stopped applying with
# 6dbf89d69b "gnttab: address fallout from XSA-501" (XSA-517). files/ holds
# a refreshed copy: the new map_grant_ref() check uses get_gt_version() and
# status_addr() so it builds with CONFIG_GRANT_TABLE_V2 disabled. Verified:
# the full OpenXT patch queue applies and the hypervisor builds with the
# OpenXT defconfig (and with GRANT_TABLE_V2=y).
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

# Pin to the stable-4.21 commit the patch queue was verified against, so a
# later stable-4.21 push cannot break the build halfway. Hypervisor and
# tools must use the same revision. Bump deliberately to pick up newer fixes.
OPENXT_XEN_SRCREV = "b734d29eea2fac3ac459ac3275a7f8790db50490"

# Swap the patch in place (later patches in the queue depend on it, so it
# must keep its position) and apply the pin. Done at the end of parsing so it
# does not depend on the order in which the xenclient-oe bbappend (which sets
# SRCREV = "${AUTOREV}") and this one are applied.
python () {
    d.setVar('SRCREV', d.getVar('OPENXT_XEN_SRCREV'))

    old = 'file://kconfig-grant-table-v2-interface.patch'
    new = 'file://kconfig-grant-table-v2-interface-xsa517.patch'
    src = (d.getVar('SRC_URI', False) or '').split()
    if old not in src:
        bb.fatal('%s not in SRC_URI, update xen-openxt-845g7.inc' % old)
    d.setVar('SRC_URI', ' '.join(new if s == old else s for s in src))
}
