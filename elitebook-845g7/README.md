# OpenXT auf dem HP EliteBook 845 G7

Diese Anleitung beschreibt, wie man ein aktuelles OpenXT (master: Xen 4.21,
Linux 6.1, Yocto dunfell) für das **HP EliteBook 845 G7** (AMD Ryzen PRO
4000 „Renoir“, Radeon-Vega-iGPU) baut und installiert.

Die Anpassungen liegen im Yocto-Layer
[`meta-openxt-elitebook-845g7`](../meta-openxt-elitebook-845g7) und werden auf
den offiziellen OpenXT-Stand (`openxt-manifest` + `bordel`) aufgesetzt.

## Was der Layer ändert

| Bereich | Problem im Upstream-OpenXT | Änderung |
|---|---|---|
| Grafik (dom0) | Kein `amdgpu`, nur `radeon` → kein Bild auf der Renoir-iGPU | `CONFIG_DRM_AMDGPU=m`, `CONFIG_DRM_AMD_DC=y`, Renoir-Firmware (`amdgpu/renoir_*.bin`) im dom0 |
| vGlass | Lädt nur `radeon`/`nouveau` kontrolliert nach dem pciback-Binding | `amdgpu` wird genauso behandelt (`discrete_gfx.conf` + `discrete_gfx_modprobe.sh`) |
| Touchpad (dom0) | `pinctrl_amd`, AMD-ACPI-Plattformgeräte und `i2c-hid-acpi` fehlen | `CONFIG_PINCTRL_AMD=y`, `CONFIG_X86_AMD_PLATFORM_DEVICE=y`, `CONFIG_I2C_HID_ACPI=m` |
| Mikrofon (dom0) | Digitales Mikrofon hängt am AMD ACP, ASoC ist aus | `CONFIG_SND_SOC_AMD_RENOIR(_MACH)=m` |
| TPM | Nur `tpm_tis`; AMD-fTPM braucht `tpm_crb` | `CONFIG_TCG_CRB` in dom0 und Installer, `tpm_crb` im dom0-initramfs |
| HP-Hotkeys | `HP_WMI` steht seit Linux 6.1 hinter einem neuen Menü und wird still verworfen | `CONFIG_X86_PLATFORM_DRIVERS_HP=y` + `CONFIG_HP_WMI` |
| Sensoren | `k10temp` fehlt | `CONFIG_SENSORS_K10TEMP=m` |
| WLAN (NDVM) | Realtek RTL8822CE (`rtw88`) fehlt | `CONFIG_RTW88_8822CE=m`, Firmware `rtw88/rtw8822c*`, `disable_aspm=1` |
| Ethernet (NDVM) | Firmware für RTL8111H fehlt | `linux-firmware-rtl8168` |
| OVMF (UEFI-Gäste) | Intel hat `PREBOOT.EXE` (E1000-PXE-Treiber) vom Server genommen → Download schlägt fehl, Build bricht ab | OVMF ohne E1000 bauen (wie in `apertussolutions/xenclient-oe`); UEFI-Gäste verlieren nur PXE-Boot über die emulierte e1000-Karte |
| QEMU (Device Model) | `wiki.qemu-project.org/download` existiert nicht mehr | Gleiches Tarball von `download.qemu.org` (Prüfsummen unverändert) |
| efibootmgr (Installer) | Upstream-Branch `master` gelöscht | Gleiche Version vom Branch `rawhide` |
| varstored (Secure Boot für VMs) | Sperrliste `dbxupdate_x64.bin` nicht mehr bei uefi.org | Byte-identische Datei aus Microsofts `secureboot_objects`-Repository |
| Java für Dojo (UI-Build) | Java-7-Bootstrap (`icedtea7-native`) braucht zehn Quellen, die nicht mehr ladbar sind (u. a. archive.apache.org: 403) | Java aus dem Build-Container (OpenJDK 8) statt Eigenbau; spart zudem Stunden |
| Xen 4.21 | Xen-Sicherheitsfix XSA-517 (13.10.2026) bricht OpenXTs Grant-Table-Patch; Xen folgt ungepinnt dem Branch-Ende | Patch an den neuen Code angepasst (komplette Patch-Queue angewendet, Hypervisor gebaut); Xen auf den geprüften Commit gepinnt |
| qemu-img unter Rosetta (Apple Silicon) | QEMU 4.2 ruft den alten `signalfd`-Syscall (Nr. 282) direkt auf; Rosetta kennt ihn nicht → Absturz beim Erzeugen der VM-Images | Backport des QEMU-Upstream-Commits `6bd17dccb6` (glibc-`signalfd()` → `signalfd4`) für `qemu-system-native` |
| Boot (xen.efi) | `openxt.cfg` startet immer tboot/Intel TXT und lädt Intel-Microcode | AMD-`openxt.cfg` ohne tboot/SINIT, AMD-Microcode (Fam. 17h), dom0 1 GiB |

Alle Kernel-Optionen werden beim Build geprüft: Fällt eine Option wegen
fehlender Abhängigkeiten weg, bricht `do_configure` mit einer Fehlermeldung
ab, statt einen Kernel ohne den Treiber zu bauen. Die Fragmente wurden gegen
die Kconfig von Linux 6.1.38 und die Upstream-defconfigs getestet.

## Build

**Schritt-für-Schritt-Anleitung für macOS/Apple Silicon (und Cloud-Server):
[BUILD-MACOS.md](BUILD-MACOS.md).**

Gebaut wird auf x86_64-Linux. Das Dockerfile in [`docker/`](docker) enthält
alle Abhängigkeiten (Ubuntu 20.04, GHC 8.10.7, `repo`). Auf einem eigenen
Linux-Host mit diesen Abhängigkeiten geht es auch direkt:

```bash
git clone https://github.com/hackyannick/OpenXT.git ~/openxt-workspace/OpenXT
OPENXT_THREADS=16 ~/openxt-workspace/OpenXT/elitebook-845g7/setup-workspace.sh ~/openxt-workspace

cd ~/openxt-workspace
openxt/bordel/bordel -i 845g7 certs create all
openxt/bordel/bordel -i 845g7 build
openxt/bordel/bordel -i 845g7 deploy iso
```

Das Skript holt den OpenXT-master-Stand per `repo`, legt mit `bordel config`
einen Build an und trägt den Layer in `conf/bblayers.conf` ein. Das ISO liegt
danach unter `build-845g7/deploy/openxt-installer.iso` und kann mit `dd` auf
einen USB-Stick geschrieben werden.

## BIOS-Einstellungen (F10)

- **Neuestes HP-BIOS installieren.** Die CPU-Microcode-Updates für Renoir
  kommen praktisch nur über das BIOS; die Datei in `linux-firmware` deckt
  Renoir nicht unbedingt ab.
- *Advanced → System Options*: **Virtualization Technology (AMD-V)** und
  **AMD IOMMU / DMA-Schutz** aktivieren (ohne IOMMU keine NDVM/USB-VM).
- *Boot Options*: **UEFI-Boot**, Legacy/CSM aus. Der BIOS-Bootpfad von
  OpenXT (GRUB → tboot) ist Intel-spezifisch und wird hier nicht unterstützt.
- *Secure Boot*: zunächst **aus**. OpenXT bringt shim mit, die Schlüssel
  müssten aber erst im BIOS hinterlegt werden.
- *Security → TPM*: aktiviert lassen (fTPM oder dTPM, beides wird erkannt).

## Installation

1. Vom USB-Stick im UEFI-Modus booten. Das ISO muss 1:1 auf den Stick
   geschrieben sein (`dd`, Rufus im DD-Modus, balenaEtcher), **nicht** per
   Ventoy: Dann findet der Installer sein Repository nicht.
2. Bei der Frage nach **Measured Launch** mit **Nein** antworten. Measured
   Launch basiert auf Intel TXT (tboot/SINIT) und existiert auf AMD nicht;
   mit „Ja“ würde das Versiegeln der Schlüssel fehlschlagen.
3. Normal fertig installieren. Der Installer kopiert `openxt.cfg`, Xen,
   Kernel und `microcode_amd_fam17h.bin` auf die EFI-Systempartition und
   legt die EFI-Boot-Einträge an.

## Getesteter Stand

Getestet auf einem HP EliteBook 845 G7, gebaut mit diesem Repository auf einem
MacBook Pro M4 (siehe [BUILD-MACOS.md](BUILD-MACOS.md)):

| Funktion | Status |
|---|---|
| Installer (UEFI, vom 1:1 geschriebenen USB-Stick) | ✅ |
| Xen-Start ohne tboot, dom0, Service-VMs | ✅ |
| Oberfläche (UIVM, vGlass) | ✅ reagiert flüssig |
| Tastatur, Touchpad | ✅ |
| WLAN (NDVM) | ✅ Netze werden gefunden |
| Akkuanzeige | ✅ |
| Gast-VM (HVM, AMD-V) | ✅ Windows-XP-Setup startet aus dem ISO |
| WLAN-Verbindung, Ton, Mikrofon, Webcam, Standby | noch nicht getestet |

## Bekannte Einschränkungen

- **Kein Measured Launch / keine DRTM.** Die TXT-basierte Vertrauenskette von
  OpenXT ist Intel-only. Eine AMD-Variante (SKINIT, z. B. über TrenchBoot)
  gibt es in OpenXT nicht.
- **Touchpad unter Xen:** Auf einigen AMD-Laptops wird der GPIO-Interrupt
  (IRQ 7) unter Xen falsch konfiguriert
  ([xen-devel-Diskussion](https://old-list-archives.xen.org/archives/html/xen-devel/2023-12/msg01766.html)).
  Auf dem getesteten 845 G7 funktioniert das Touchpad. Falls es auf einem
  anderen Gerät nicht reagiert: auf der ESP in `EFI/OpenXT/openxt.cfg` an die
  `options=`-Zeile von `[openxt-normal]` `ioapic_ack=new` anhängen.
- **Suspend:** Laut demselben HCL-Bericht funktioniert Standby unter Xen.
  Falls das BIOS nur „Modern Standby“ (S0ix) anbietet, geht es nicht, weil
  Xen kein S0ix unterstützt.
- **CPU-Frequenzskalierung:** Upstream deaktiviert
  `CONFIG_XEN_ACPI_PROCESSOR` im dom0, Xen bekommt dadurch keine P-State-Daten
  aus ACPI. Das betrifft alle Plattformen und wurde hier bewusst nicht
  geändert.
- **Fingerabdruckleser, Smartcard-Leser, Webcam** sind USB-Geräte und werden
  wie üblich über USB-Passthrough an VMs gegeben; eigene Treiber im dom0 sind
  dafür nicht nötig.

## Fehlersuche

- Kein Bild nach dem Xen-Start: EFI-Eintrag **„OpenXT (console)“** wählen,
  dann im dom0 `dmesg | grep -i amdgpu` und `ls /lib/firmware/amdgpu/renoir_*`
  prüfen.
- WLAN: in der NDVM `dmesg | grep -iE "rtw88|iwlwifi"`.
- TPM: im dom0 `ls /sys/class/tpm/` und `dmesg | grep -i tpm`.
