# OpenXT auf AMD-Ryzen-Laptops

Diese Anleitung beschreibt, wie man ein aktuelles OpenXT (master: Xen 4.21,
Linux 6.1, Yocto dunfell) für AMD-Ryzen-Laptops baut und installiert.
Unterstützt werden:

| Gerät | Plattform | Status | Gerätehinweise |
|---|---|---|---|
| HP EliteBook 845 G7 | Ryzen PRO 4000 „Renoir“, Radeon Vega | auf dem Gerät getestet | [elitebook-845g7.md](elitebook-845g7.md) |
| Lenovo ThinkPad Z13 Gen1 | Ryzen PRO 6000 „Rembrandt“, Radeon 660M/680M | gebaut und geprüft, noch nicht auf dem Gerät getestet | [thinkpad-z13-gen1.md](thinkpad-z13-gen1.md) |

Ein Build bzw. ein Installer-ISO funktioniert für beide Geräte. Die
Anpassungen liegen im Yocto-Layer
[`meta-openxt-amd-laptops`](../meta-openxt-amd-laptops) und werden auf den
offiziellen OpenXT-Stand (`openxt-manifest` + `bordel`) aufgesetzt.

## Was der Layer ändert

| Bereich | Problem im Upstream-OpenXT | Änderung |
|---|---|---|
| Grafik (dom0) | Kein `amdgpu`, nur `radeon` → kein Bild auf Renoir/Rembrandt | `CONFIG_DRM_AMDGPU=m`, `CONFIG_DRM_AMD_DC=y`, Firmware `amdgpu/renoir_*` und `amdgpu/yellow_carp_*` im dom0 |
| vGlass | Lädt nur `radeon`/`nouveau` kontrolliert nach dem pciback-Binding | `amdgpu` wird genauso behandelt (`discrete_gfx.conf` + `discrete_gfx_modprobe.sh`) |
| Touchpad (dom0) | `pinctrl_amd`, AMD-ACPI-Plattformgeräte und `i2c-hid-acpi` fehlen | `CONFIG_PINCTRL_AMD=y`, `CONFIG_X86_AMD_PLATFORM_DEVICE=y`, `CONFIG_I2C_HID_ACPI=m` |
| Mikrofon (dom0) | Digitale Mikrofone hängen am AMD ACP, ASoC ist aus | `CONFIG_SND_SOC_AMD_RENOIR(_MACH)=m` (845 G7), `CONFIG_SND_SOC_AMD_ACP6x`/`_YC_MACH=m` (Z13) |
| Lautsprecher Z13 (dom0) | Cirrus-CS35L41-Verstärker am ALC287 werden nicht unterstützt | `CONFIG_SND_HDA_SCODEC_CS35L41_I2C`, `CONFIG_SERIAL_MULTI_INSTANTIATE` (+ `CONFIG_SPI`), Firmware `cirrus/cs35l41*` |
| TPM | Nur `tpm_tis`; AMD-fTPM und Pluton brauchen `tpm_crb` | `CONFIG_TCG_CRB` in dom0 und Installer, `tpm_crb` im dom0-initramfs |
| HP-Hotkeys | `HP_WMI` steht seit Linux 6.1 hinter einem neuen Menü und wird still verworfen | `CONFIG_X86_PLATFORM_DRIVERS_HP=y` + `CONFIG_HP_WMI` |
| Sensoren | `k10temp` fehlt | `CONFIG_SENSORS_K10TEMP=m` |
| WLAN (NDVM) | Realtek RTL8822CE (`rtw88`, 845 G7) und Qualcomm WCN6855 (`ath11k`, Z13) fehlen | `CONFIG_RTW88_8822CE=m` + `disable_aspm=1`, `CONFIG_ATH11K_PCI=m`, Firmware `rtw88/rtw8822c*` und `ath11k/WCN6855` |
| Ethernet (NDVM) | Firmware für RTL8111H fehlt | `linux-firmware-rtl8168` |
| OVMF (UEFI-Gäste) | Intel hat `PREBOOT.EXE` (E1000-PXE-Treiber) vom Server genommen → Download schlägt fehl, Build bricht ab | OVMF ohne E1000 bauen (wie in `apertussolutions/xenclient-oe`); UEFI-Gäste verlieren nur PXE-Boot über die emulierte e1000-Karte |
| QEMU (Device Model) | `wiki.qemu-project.org/download` existiert nicht mehr | Gleiches Tarball von `download.qemu.org` (Prüfsummen unverändert) |
| efibootmgr (Installer) | Upstream-Branch `master` gelöscht | Gleiche Version vom Branch `rawhide` |
| varstored (Secure Boot für VMs) | Sperrliste `dbxupdate_x64.bin` nicht mehr bei uefi.org | Byte-identische Datei aus Microsofts `secureboot_objects`-Repository |
| Java für Dojo (UI-Build) | Java-7-Bootstrap (`icedtea7-native`) braucht zehn Quellen, die nicht mehr ladbar sind (u. a. archive.apache.org: 403) | Java aus dem Build-Container (OpenJDK 8) statt Eigenbau; spart zudem Stunden |
| Xen 4.21 | Xen-Sicherheitsfix XSA-517 (13.10.2026) bricht OpenXTs Grant-Table-Patch; Xen folgt ungepinnt dem Branch-Ende | Patch an den neuen Code angepasst (komplette Patch-Queue angewendet, Hypervisor gebaut); Xen auf den geprüften Commit gepinnt |
| qemu-img unter Rosetta (Apple Silicon) | QEMU 4.2 ruft den alten `signalfd`-Syscall (Nr. 282) direkt auf; Rosetta kennt ihn nicht → Absturz beim Erzeugen der VM-Images | Backport des QEMU-Upstream-Commits `6bd17dccb6` (glibc-`signalfd()` → `signalfd4`) für `qemu-system-native` |
| Statusleiste (vGlass) | 25 Pixel hohe Leiste über jeder VM; verhindert 1:1-Auflösungen | Standardhöhe 0 (Patch für vGlass); wieder einschaltbar mit `db-write /disman/banner_height 25` in der dom0 |
| Boot (xen.efi) | `openxt.cfg` startet immer tboot/Intel TXT und lädt Intel-Microcode | AMD-`openxt.cfg` ohne tboot/SINIT, AMD-Microcode (Family 17h + 19h in `microcode_amd.bin`), dom0 1 GiB |

Alle Kernel-Optionen werden beim Build geprüft: Fällt eine Option wegen
fehlender Abhängigkeiten weg, bricht `do_configure` mit einer Fehlermeldung
ab, statt einen Kernel ohne den Treiber zu bauen. Die Fragmente wurden gegen
die Kconfig von Linux 6.1.38 und die Upstream-defconfigs getestet.

## Build

**Schritt-für-Schritt-Anleitungen:**

- **Windows (WSL2), empfohlen auf x86-Laptops:** [BUILD-WINDOWS.md](BUILD-WINDOWS.md)
  (ein PowerShell-Skript erledigt alles)
- **macOS/Apple Silicon und Cloud-Server:** [BUILD-MACOS.md](BUILD-MACOS.md)

Gebaut wird auf x86_64-Linux. Das Dockerfile in [`docker/`](docker) enthält
alle Abhängigkeiten (Ubuntu 20.04, GHC 8.10.7, OpenJDK 8, `repo`), installiert
über `docker/install-build-deps.sh`. Auf einem eigenen
Linux-Host mit diesen Abhängigkeiten geht es auch direkt:

```bash
git clone https://github.com/hackyannick/OpenXT.git ~/openxt-workspace/OpenXT
OPENXT_THREADS=16 ~/openxt-workspace/OpenXT/amd-laptops/setup-workspace.sh ~/openxt-workspace

cd ~/openxt-workspace
openxt/bordel/bordel -i 845g7 certs create all
openxt/bordel/bordel -i 845g7 build
openxt/bordel/bordel -i 845g7 deploy iso
```

Das Skript holt den OpenXT-master-Stand per `repo`, legt mit `bordel config`
einen Build an und trägt den Layer in `conf/bblayers.conf` ein. Das ISO liegt
danach unter `build-845g7/deploy/openxt-installer.iso` und kann mit `dd` auf
einen USB-Stick geschrieben werden.

## BIOS-Einstellungen

Gerätespezifisch, siehe [elitebook-845g7.md](elitebook-845g7.md) bzw.
[thinkpad-z13-gen1.md](thinkpad-z13-gen1.md). Für alle Geräte gilt:
neuestes BIOS installieren, AMD-V und IOMMU an, UEFI-Boot, Secure Boot
zunächst aus.

## Installation

1. Vom USB-Stick im UEFI-Modus booten. Das ISO muss 1:1 auf den Stick
   geschrieben sein (`dd`, Rufus im DD-Modus, balenaEtcher), **nicht** per
   Ventoy: Dann findet der Installer sein Repository nicht.
2. Bei der Frage nach **Measured Launch** mit **Nein** antworten. Measured
   Launch basiert auf Intel TXT (tboot/SINIT) und existiert auf AMD nicht;
   mit „Ja“ würde das Versiegeln der Schlüssel fehlschlagen.
3. Normal fertig installieren. Der Installer kopiert `openxt.cfg`, Xen,
   Kernel und `microcode_amd.bin` auf die EFI-Systempartition und
   legt die EFI-Boot-Einträge an.

## Bekannte Einschränkungen

- **Kein Measured Launch / keine DRTM.** Die TXT-basierte Vertrauenskette von
  OpenXT ist Intel-only. Eine AMD-Variante (SKINIT, z. B. über TrenchBoot)
  gibt es in OpenXT nicht.
- **Touchpad unter Xen:** Auf einigen AMD-Laptops wird der GPIO-Interrupt
  (IRQ 7) unter Xen falsch konfiguriert
  ([xen-devel-Diskussion](https://old-list-archives.xen.org/archives/html/xen-devel/2023-12/msg01766.html)).
  Auf dem 845 G7 funktioniert das Touchpad. Falls es nicht reagiert: auf der
  ESP in `EFI/OpenXT/openxt.cfg` an die `options=`-Zeile von
  `[openxt-normal]` `ioapic_ack=new` anhängen.
- **Standby:** Xen unterstützt kein „Modern Standby“ (S0ix). Standby geht nur,
  wenn das Gerät klassisches S3 kann (845 G7 laut Qubes-HCL ja, Z13 Gen1
  siehe Gerätehinweise).
- **CPU-Microcode:** Die `amd-ucode`-Dateien aus `linux-firmware` enthalten
  weder Renoir (Family 17h, Modell 60h) noch Rembrandt (Family 19h,
  Modell 44h). Microcode-Updates kommen für beide Geräte nur über BIOS-Updates.
- **CPU-Frequenzskalierung:** Upstream deaktiviert
  `CONFIG_XEN_ACPI_PROCESSOR` im dom0, Xen bekommt dadurch keine P-State-Daten
  aus ACPI. Das betrifft alle Plattformen und wurde hier bewusst nicht
  geändert.
- **Fingerabdruckleser, Smartcard-Leser, Webcam** sind USB-Geräte und werden
  wie üblich über USB-Passthrough an VMs gegeben; eigene Treiber im dom0 sind
  dafür nicht nötig.

## Konsole (dom0)

In der laufenden Oberfläche fängt vGlass alle Tastenkombinationen ab;
Ctrl+Alt+F2 funktioniert nicht. Der Installer legt zwar einen EFI-Eintrag
„OpenXT (console)“ an, viele Firmwares (z. B. HP) zeigen aber nur einen
OpenXT-Eintrag an. Dann:

1. Vom Installations-Stick booten, in GRUB bei „OpenXT Install“ `e` drücken,
   in der `linux`-Zeile `start_install=new` löschen, mit Ctrl-X starten und
   als `root` ohne Passwort anmelden.
2. EFI-Partition der internen SSD einhängen und den Standard umstellen:
   ```bash
   blkid | grep -i vfat                 # meist /dev/nvme0n1p1
   mount /dev/nvme0n1p1 /mnt
   sed -i 's/^default=openxt-normal/default=openxt-support-console/' /mnt/EFI/OpenXT/openxt.cfg
   umount /mnt; reboot
   ```
3. OpenXT startet in die Textkonsole (Login `root` + Installationspasswort).
   Zurück geht es mit derselben `sed`-Zeile in umgekehrter Richtung.

Unbedenklich, da ohne Measured Launch nichts versiegelt ist.

## Darstellung der Gast-VMs

vGlass skaliert das Bild einer VM ungeglättet und getrennt in Breite und Höhe
auf die volle Bildfläche unter der Statusleiste. Jede Gast-Auflösung, die
nicht exakt zur Bildfläche passt, wird dadurch ungleichmäßig verzerrt und
wirkt unscharf. Abhilfe:

- Im Gast genau die native Auflösung einstellen (845 G7: 1920×1080,
  Z13: 1920×1200 bzw. 2880×1800 beim OLED). Das geht nur ohne Statusleiste;
  dieser Build blendet sie deshalb standardmäßig aus.
- Beim Z13-OLED ist 1440×900 im Gast ein guter Kompromiss: genau halbe
  Auflösung, also ganzzahlige Verdopplung ohne Verzerrung.
- Bietet Windows die gewünschte Auflösung nicht an, reicht meist der
  Grafikspeicher der VM nicht (2880×1800 bei 32 Bit braucht über 20 MB).

## Fehlersuche

- Kein Bild nach dem Xen-Start: Konsole öffnen (siehe oben), dann im dom0
  `dmesg | grep -i amdgpu` und `ls /lib/firmware/amdgpu/` prüfen.
- WLAN: in der NDVM `dmesg | grep -iE "rtw88|iwlwifi|ath11k"`.
- TPM: im dom0 `ls /sys/class/tpm/` und `dmesg | grep -i tpm`.
- Ton (Z13): im dom0 `dmesg | grep -iE "cs35l41|acp6x|snd"`.
