# OpenXT für AMD-Ryzen-Laptops

Dieser Fork ergänzt OpenXT um Hardware-Unterstützung für AMD-Ryzen-Laptops:

- **HP EliteBook 845 G7** (Ryzen PRO 4000 „Renoir“): auf dem Gerät getestet
- **Lenovo ThinkPad Z13 Gen1** (Ryzen PRO 6000 „Rembrandt“): gebaut und
  geprüft, noch nicht auf dem Gerät getestet

Inhalt:

- [`meta-openxt-amd-laptops/`](meta-openxt-amd-laptops) – Yocto-Layer
  mit den Anpassungen (Kernel, Firmware, Boot-Konfiguration, vGlass,
  Build-Fixes für tote Download-Links).
- [`amd-laptops/`](amd-laptops) – Anleitung zu Build (Windows/WSL2,
  macOS/Apple Silicon), Installation, Gerätehinweisen und bekannten Einschränkungen,
  dazu Einrichtungsskript und Docker-Build-Umgebung.

Die Verzeichnisse hießen früher `meta-openxt-elitebook-845g7/` und
`elitebook-845g7/`; die alten Namen bleiben als symbolische Links erhalten,
damit bestehende Build-Workspaces weiter funktionieren.

Gebaut wird der aktuelle OpenXT-Stand (master: Xen 4.21, Linux 6.1, Yocto
dunfell) über [openxt-manifest](https://github.com/OpenXT/openxt-manifest) und
[bordel](https://github.com/OpenXT/bordel); der Layer wird obendrauf gelegt.

## Ursprüngliches Build-System (veraltet)

Die übrigen Dateien in diesem Repository (`do_build.sh`, `build-scripts/`,
…) stammen aus dem Upstream-Repository
[OpenXT/openxt](https://github.com/OpenXT/openxt). Upstream hat sie 2021
eingestellt; sie bauen nur stable-9 und älter und werden für diesen
Build nicht verwendet. Originalhinweis:

> UNMAINTAINED!!!  Please use [bordel](https://github.com/OpenXT/bordel)
>
> This build system only supports stable-9 and earlier.  For xenclient-oe.git as
> of [the merging of vGlass](https://github.com/OpenXT/xenclient-oe/commit/8522fd8c43d57c33cece73a26b4c7498f3d8a58d), see
> [bordel](https://github.com/OpenXT/bordel)
>
> See [the OpenXT wiki](https://github.com/openxt/openxt/wiki) for more
> information. Specifically, see the [How to build OpenXT
> page](https://github.com/OpenXT/openxt/wiki/How-to-build-OpenXT).
