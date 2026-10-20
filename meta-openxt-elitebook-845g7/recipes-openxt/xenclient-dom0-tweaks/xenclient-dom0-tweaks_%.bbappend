# Replace xenclient-oe's openxt.cfg (xen.efi configuration) with the AMD
# variant from files/. Differences to the Intel default:
#  - no TXT launch entries in [global]: Intel TXT does not exist on AMD CPUs,
#    so there is no DRTM/measured launch on this platform;
#  - AMD Family 17h microcode instead of the Intel blob;
#  - dom0 gets 1 GiB instead of 768 MiB (amdgpu needs more GTT memory).
# Section names are unchanged, the installer creates EFI boot entries for them.
#
# The file deliberately has no comments: openxt-measuredlaunch's
# parse_eficfg greps the raw lines for keywords.
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
