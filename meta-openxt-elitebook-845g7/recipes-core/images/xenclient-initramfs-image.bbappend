# AMD fTPM (CRB interface), see initramfs-framework_%.bbappend.
IMAGE_INSTALL_append = " \
    kernel-module-tpm-crb \
"
