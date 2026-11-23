# meta-openxt-amd-laptops

Hardware enablement for AMD Ryzen laptops on top of OpenXT master
(`xenclient-oe`, Yocto dunfell):

- HP EliteBook 845 G7 (Ryzen PRO 4000 "Renoir"), tested on the device
- Lenovo ThinkPad Z13 Gen1 (Ryzen PRO 6000 "Rembrandt"), not yet tested on
  the device

One build supports both. Depends on: `core`, `xenclient-oe`, `vglass`.

See [`../amd-laptops/README.md`](../amd-laptops/README.md) (German) for
build, BIOS and installation instructions, device notes and known
limitations. This directory used to be called `meta-openxt-elitebook-845g7`;
a symlink with the old name keeps existing workspaces working.

## Contents

- `recipes-kernel/linux`: Kconfig fragments for the dom0, NDVM and installer
  kernels: amdgpu, AMD GPIO/I2C/HID for touchpads, ACP DMIC (Renoir and
  ACP6x/Yellow Carp), CS35L41 HDA side codecs with serial-multi-instantiate
  (Z13 speakers), tpm_crb, hp-wmi, k10temp, rtw88 8822CE and ath11k PCI. The
  bbappend fails `do_configure` if an option is dropped by `olddefconfig`.
- `recipes-kernel/linux-firmware`: splits `amdgpu/renoir_*`,
  `amdgpu/yellow_carp_*`, `amd-ucode` and `cirrus/cs35l41*` out of the
  catch-all package and installs `/boot/microcode_amd.bin` (Family 17h + 19h
  containers) for xen.efi.
- `recipes-core/images`: adds the firmware packages to dom0/NDVM/installer and
  `tpm_crb` to the dom0 initramfs.
- `recipes-core/initrdscripts`: loads `tpm_crb` next to `tpm_tis`.
- `recipes-openxt/xenclient-dom0-tweaks`: AMD `openxt.cfg` (no tboot/SINIT,
  AMD microcode, 1 GiB dom0).
- `recipes-openxt/xenclient-ndvm-tweaks`: `rtw88_pci disable_aspm=1`.
- `recipes-graphics/vglass`: load amdgpu the same way as radeon; hide the
  banner by default (`g_banner_height` 0, re-enable via disman).
- `recipes-core/ovmf`, `recipes-extended/qemu-dm`, `recipes-bsp/efibootmgr`,
  `recipes-core/varstored`: workarounds for dead upstream download links
  (Intel PREBOOT.EXE, wiki.qemu-project.org, efibootmgr `master` branch,
  uefi.org dbx). Not device specific; drop them once xenclient-oe master
  carries equivalent fixes.
- `recipes-extended/xen`: refreshed kconfig-grant-table-v2-interface patch for
  stable-4.21 after XSA-517, and Xen pinned to the verified commit.
- `recipes-devtools/qemu`: backport QEMU 6bd17dccb6 to qemu-system-native so
  qemu-img does not use the legacy signalfd syscall, which Rosetta 2 does not
  implement (x86_64 build containers on Apple Silicon).
- `recipes-devtools/dojo` + `HOSTTOOLS_append = " java"` in `conf/layer.conf`:
  run the Dojo UI build with the host Java instead of building icedtea7-native
  and the meta-java bootstrap chain (several of its sources are gone). The
  build host needs a Java runtime (the Docker image ships OpenJDK 8).

Note that this layer makes the build AMD-specific: the replaced `openxt.cfg`
no longer starts tboot, so Intel machines installed from this build lose
measured launch.
