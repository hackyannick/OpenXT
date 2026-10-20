# xenclient-oe's tpm/tpm2 initramfs modules only load tpm_tis. AMD platforms
# configured for the firmware TPM (fTPM) expose it through the CRB interface
# instead; load tpm_crb as well (it is a no-op on TIS-only machines).
#
# Run as a postfunc so this happens after xenclient-oe's do_install_append
# installed the scripts, regardless of bbappend ordering.
do_install[postfuncs] += "openxt_initramfs_load_tpm_crb"

openxt_initramfs_load_tpm_crb() {
    for script in 92-tpm 92-tpm2; do
        grep -q 'load_kernel_module tpm_tis$' ${D}/init.d/${script} ||
            bbfatal "${script}: tpm_tis load not found, update this bbappend"
        sed -i 's/^\(\s*\)load_kernel_module tpm_tis$/&\n\1load_kernel_module tpm_crb/' \
            ${D}/init.d/${script}
    done
}
