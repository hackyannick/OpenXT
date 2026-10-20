# vGlass keeps discrete GPU drivers from binding before passthrough GPUs are
# handed to pciback, then loads them itself. It only knows radeon and nouveau;
# AMD GPUs supported by amdgpu only (e.g. the 845 G7's Renoir iGPU) would
# either bind too early or never. Treat amdgpu the same way as radeon.
do_install_append() {
    echo "install amdgpu /bin/false" >> ${D}${sysconfdir}/modprobe.d/discrete_gfx.conf

    grep -q '^modprobe --ignore-install radeon$' ${D}${bindir}/discrete_gfx_modprobe.sh ||
        bbfatal "discrete_gfx_modprobe.sh changed, update this bbappend"
    sed -i 's/^modprobe --ignore-install radeon$/modprobe --ignore-install amdgpu\n&/' \
        ${D}${bindir}/discrete_gfx_modprobe.sh
}
