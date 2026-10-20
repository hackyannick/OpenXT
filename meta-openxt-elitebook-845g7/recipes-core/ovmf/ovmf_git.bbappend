# Intel removed PREBOOT.EXE from downloadmirror.intel.com (404), so
# xenclient-oe's ovmf bbappend can no longer fetch the proprietary E1000 UEFI
# driver it embeds for guest PXE boot. Build OVMF without it, as done in
# apertussolutions/xenclient-oe 48b5e7a1 ("ovmf: drop Intel PREBOOT.EXE
# download and E1000 firmware"). UEFI guests lose PXE boot over the emulated
# e1000 NIC; everything else is unchanged.
#
# Drop this file once xenclient-oe master carries that fix.

SRC_URI_remove = "https://downloadmirror.intel.com/29334/eng/PREBOOT.EXE;unpack=0;name=PREBOOT"

deltask do_extract_bootutil

# xenclient-oe appends an E1000 rebuild to do_compile_class-target. An _append
# cannot be removed by another bbappend, so filter it out of the pending
# appends and replace it with the same build minus -D E1000_ENABLE. The output
# keeps the ovmf.e1000.* names so xenclient-oe's do_install append still works.
python () {
    appends = d.getVarFlag('do_compile_class-target', '_append', False) or []
    kept = [a for a in appends if 'E1000_ENABLE' not in a[0]]
    if len(kept) == len(appends):
        bb.fatal("ovmf: xenclient-oe E1000 do_compile append not found, update this bbappend")
    d.setVarFlag('do_compile_class-target', '_append', kept)
}

do_compile_class-target_append() {
    bbnote "Building with Xen variable support (no E1000)."
    rm -rf ${S}/Build/Ovmf$OVMF_DIR_SUFFIX
    ${S}/OvmfPkg/build.sh $PARALLEL_JOBS -a $OVMF_ARCH -b RELEASE -t ${FIXED_GCCVER} -D XEN_VARIABLE_ENABLE=TRUE -D SECURE_BOOT_ENABLE=TRUE
    ln ${build_dir}/FV/OVMF.fd ${WORKDIR}/ovmf/ovmf.e1000.fd
    ln ${build_dir}/FV/OVMF_CODE.fd ${WORKDIR}/ovmf/ovmf.e1000.code.fd
}
