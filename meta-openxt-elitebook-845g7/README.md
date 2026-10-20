# meta-openxt-elitebook-845g7

Hardware enablement for the HP EliteBook 845 G7 (AMD Ryzen PRO 4000 "Renoir")
on top of OpenXT master (`xenclient-oe`, Yocto dunfell).

Depends on: `core`, `xenclient-oe`, `vglass`.

See [`../elitebook-845g7/README.md`](../elitebook-845g7/README.md) (German)
for build, BIOS and installation instructions and known limitations.

## Contents

- `recipes-kernel/linux`: Kconfig fragments for the dom0, NDVM and installer
  kernels (amdgpu, AMD GPIO/I2C/HID for the touchpad, ACP DMIC, tpm_crb,
  hp-wmi, k10temp, rtw88). The bbappend fails `do_configure` if an option is
  dropped by `olddefconfig`.
- `recipes-kernel/linux-firmware`: splits `amdgpu/renoir_*` and `amd-ucode`
  out of the catch-all package and installs `/boot/microcode_amd_fam17h.bin`
  for xen.efi.
- `recipes-core/images`: adds the firmware packages to dom0/NDVM/installer and
  `tpm_crb` to the dom0 initramfs.
- `recipes-core/initrdscripts`: loads `tpm_crb` next to `tpm_tis`.
- `recipes-openxt/xenclient-dom0-tweaks`: AMD `openxt.cfg` (no tboot/SINIT,
  AMD microcode, 1 GiB dom0).
- `recipes-openxt/xenclient-ndvm-tweaks`: `rtw88_pci disable_aspm=1`.
- `recipes-graphics/vglass`: load amdgpu the same way as radeon.
- `recipes-core/ovmf`, `recipes-extended/qemu-dm`, `recipes-bsp/efibootmgr`,
  `recipes-core/varstored`: workarounds for dead upstream download links
  (Intel PREBOOT.EXE, wiki.qemu-project.org, efibootmgr `master` branch,
  uefi.org dbx). Not 845 G7 specific; drop them once xenclient-oe master
  carries equivalent fixes.
- `recipes-devtools/dojo` + `HOSTTOOLS_append = " java"` in `conf/layer.conf`:
  run the Dojo UI build with the host Java instead of building icedtea7-native
  and the meta-java bootstrap chain (several of its sources are gone). The
  build host needs a Java runtime (the Docker image ships OpenJDK 8).

Note that this layer makes the build AMD-specific: the replaced `openxt.cfg`
no longer starts tboot, so Intel machines installed from this build lose
measured launch.
