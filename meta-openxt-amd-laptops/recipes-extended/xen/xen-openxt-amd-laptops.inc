# Shared by the bbappends of every recipe built from the Xen tree with
# xen-common.inc: xen_git, xen-tools_git and xen-ocaml-libs.
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
# later stable-4.21 push cannot break the build halfway. Hypervisor, tools
# and the OCaml xenstored must use the same revision. Bump deliberately to
# pick up newer fixes.
#
# The pin must be visible during parsing: BitBake resolves PV (and with it
# WORKDIR, the pseudo database and the sysroot paths) from SRCREV before
# anonymous python runs, so setting SRCREV there left those paths on the
# AUTOREV commit while the source was the pinned one. That broke do_install
# (pseudo abort) and do_package as soon as stable-4.21 moved on. The
# forcevariable override wins over the xenclient-oe bbappend's
# SRCREV = "${AUTOREV}" regardless of the order the bbappends are applied.
OPENXT_XEN_SRCREV = "b734d29eea2fac3ac459ac3275a7f8790db50490"
SRCREV_forcevariable = "${OPENXT_XEN_SRCREV}"

# Swap the patch in place (later patches in the queue depend on it, so it
# must keep its position). Done at the end of parsing so the full SRC_URI
# is known.
python () {
    old = 'file://kconfig-grant-table-v2-interface.patch'
    new = 'file://kconfig-grant-table-v2-interface-xsa517.patch'
    src = (d.getVar('SRC_URI', False) or '').split()
    if old not in src:
        bb.fatal('%s not in SRC_URI, update xen-openxt-amd-laptops.inc' % old)
    d.setVar('SRC_URI', ' '.join(new if s == old else s for s in src))
}
