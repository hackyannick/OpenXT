# Lenovo ThinkPad Z13 Gen1

AMD Ryzen PRO 6000 („Rembrandt“, Ryzen 5 PRO 6650U / 7 PRO 6850U /
7 PRO 6860Z), Radeon 660M/680M, 13,3" mit 1920×1200 (IPS) oder 2880×1800
(OLED). Allgemeine Build- und Installationsanleitung: [README.md](README.md).

**Status: gebaut und geprüft, aber noch nicht auf dem Gerät getestet.** Die
Kernel-Optionen sind gegen die Kconfig von Linux 6.1.38 und die
OpenXT-defconfigs geprüft, die Firmware-Dateien gegen linux-firmware
20240220 (den Stand in Yocto dunfell). Rückmeldungen vom Gerät fließen in die
Tabelle unten ein.

## BIOS-Einstellungen (F1)

Die Menünamen unterscheiden sich je nach BIOS-Version leicht.

- **Neuestes Lenovo-BIOS installieren.** CPU-Microcode-Updates für Rembrandt
  kommen nur über das BIOS.
- *Security → Virtualization*: **AMD Virtualization Technology** und
  **AMD IOMMU** (bzw. „Kernel DMA Protection“/DMA-Schutz) aktivieren.
- *Security → Secure Boot*: **aus**.
- *Startup*: UEFI-Boot (Legacy gibt es auf diesem Gerät nicht).
- *Security → Security Chip*: aktiviert lassen. Sowohl AMD fTPM als auch
  Pluton werden vom Kernel unterstützt (`tpm_crb`). Bei TPM-Problemen im
  Installer auf AMD fTPM umstellen.
- *Config → Power → Sleep State*: falls eine Option „Linux“ (S3) angeboten
  wird, diese wählen. Ohne S3 funktioniert unter Xen kein Standby.

## Hardware

| Komponente | ID | Treiber | Hinweis |
|---|---|---|---|
| Radeon 660M/680M (Yellow Carp) | | `amdgpu` | Firmware `amdgpu/yellow_carp_*`; Display Core DCN 3.1 |
| WLAN Qualcomm WCN6855 (NFA725A, Wi-Fi 6E) | `17cb:1103` | `ath11k_pci` (NDVM) | Firmware `ath11k/WCN6855/hw2.0` (hw2.1 verlinkt); fällt bei der Durchreichung auf einen einzelnen MSI-Interrupt zurück |
| Touchpad (ELAN ForcePad) | `04f3:3231` | `i2c-hid-acpi`, `hid-multitouch`, `pinctrl-amd` | |
| TrackPoint | | `psmouse` | unter Linux teils eingeschränkt |
| Tastatur, Hotkeys | | `atkbd`, `thinkpad_acpi` | |
| Ton: Realtek ALC287 (Subsystem `17aa:22f1`/`22f2`) | `1002:1640` (HDMI) | `snd-hda-intel` | Quirk `ALC287_FIXUP_CS35L41_I2C_2` in Linux 6.1 |
| Lautsprecherverstärker 2× Cirrus CS35L41 (I2C, ACPI `CSC3551`) | | `snd-hda-scodec-cs35l41-i2c`, `serial-multi-instantiate` | Firmware `cirrus/cs35l41-dsp1-spk-*-17aa22f1*` |
| Digitale Mikrofone (ACP 6.x) | | `snd-pci-acp6x`, `snd-acp6x-mach` | DMI `21D2`/`21D3` in Linux 6.1 hinterlegt |
| TPM (AMD fTPM / Pluton) | | `tpm_crb` | Pluton-Unterstützung ist in 6.1.38 enthalten |
| USB4 | | – | nicht aktiviert: USB-Geräte laufen über xHCI, USB4-/DisplayPort-Tunneling zu Docks voraussichtlich nicht |
| Webcam, Fingerabdruckleser | | – | USB-Geräte, Durchreichung an VMs |

Quellen für die IDs: Hardware-Tabelle der ArchWiki-Seite
[Lenovo ThinkPad Z13/Z16 Gen 1](https://wiki.archlinux.org/title/Lenovo_ThinkPad_Z13/Z16_Gen_1)
(dort Audio und TrackPoint als „teilweise“ markiert) und
[ThinkPad Z series](https://en.wikipedia.org/wiki/ThinkPad_Z_series);
Treiberzuordnung aus dem Quellcode von Linux 6.1.38.

## Erwartungen und offene Punkte

- **OLED, 2880×1800:** `amdgpu` treibt das Panel; ob die Oberfläche der UIVM
  hochskaliert wird (HiDPI), ist offen. Gast-VMs am besten mit 1440×900
  (genau halbe Auflösung) oder nativ betreiben, siehe
  [README.md → Darstellung der Gast-VMs](README.md#darstellung-der-gast-vms).
- **Lautsprecher:** brauchen die CS35L41-Firmware und den Treiber im dom0;
  Kopfhörer und HDMI-Ton laufen auch ohne.
- **Standby:** nur mit S3-Option im BIOS (siehe oben).
- **Ethernet:** hat das Gerät nicht; USB-Netzwerkadapter werden über die
  NDVM bzw. USB-Durchreichung angebunden.

## Getesteter Stand

| Funktion | Status |
|---|---|
| Alles | noch nicht auf dem Gerät getestet |
