# HP EliteBook 845 G7

AMD Ryzen PRO 4000 („Renoir“), Radeon-Vega-iGPU. Allgemeine Build- und
Installationsanleitung: [README.md](README.md).

## BIOS-Einstellungen (F10)

- **Neuestes HP-BIOS installieren.** CPU-Microcode-Updates für Renoir kommen
  nur über das BIOS.
- *Advanced → System Options*: **Virtualization Technology (AMD-V)** und
  **AMD IOMMU / DMA-Schutz** aktivieren (ohne IOMMU keine NDVM/USB-VM).
- *Boot Options*: **UEFI-Boot**, Legacy/CSM aus. Der BIOS-Bootpfad von
  OpenXT (GRUB → tboot) ist Intel-spezifisch und wird nicht unterstützt.
- *Secure Boot*: **aus**. Der Installer-Bootloader ist nicht signiert.
- *Security → TPM*: aktiviert lassen (fTPM oder dTPM, beides wird erkannt).

Das HP-Bootmenü (F9) zeigt nur einen OpenXT-Eintrag; für die Konsole siehe
[README.md → Konsole](README.md#konsole-dom0).

## Hardware

| Komponente | Treiber | Hinweis |
|---|---|---|
| Radeon Vega (Renoir) | `amdgpu` | Firmware `amdgpu/renoir_*` |
| Touchpad | `i2c-hid-acpi`, `pinctrl-amd` | |
| WLAN: Realtek RTL8822CE oder Intel AX200 | `rtw88_pci` bzw. `iwlwifi` (NDVM) | `rtw88_pci disable_aspm=1` |
| Ethernet RTL8111 | `r8169` (NDVM) | Firmware `rtl_nic/rtl8168h*` |
| Ton: Realtek HDA + Mikrofon am ACP | `snd-hda-intel`, `snd-rn-pci-acp3x` | |
| TPM (fTPM oder dTPM) | `tpm_crb` / `tpm_tis` | |
| Hotkeys | `hp-wmi` | |

## Getesteter Stand

Gebaut mit diesem Repository auf einem MacBook Pro M4
(siehe [BUILD-MACOS.md](BUILD-MACOS.md)):

| Funktion | Status |
|---|---|
| Installer (UEFI, vom 1:1 geschriebenen USB-Stick) | ✅ |
| Xen-Start ohne tboot, dom0, Service-VMs | ✅ |
| Oberfläche (UIVM, vGlass) | ✅ reagiert flüssig |
| Tastatur, Touchpad | ✅ |
| WLAN (NDVM) | ✅ Netze werden gefunden |
| Akkuanzeige | ✅ |
| Gast-VM (HVM, AMD-V) | ✅ Windows XP installiert, Windows 7 läuft |
| Windows-Gast-Tools (OpenXT 9.0.x) | ⚠️ Windows 7 x64 nur im Testmodus; XP: Bluescreen nach Installation |
| Windows 8.1 | ❌ startet nicht (Ursache offen) |
| WLAN-Verbindung, Ton, Mikrofon, Webcam, Standby | noch nicht getestet |
