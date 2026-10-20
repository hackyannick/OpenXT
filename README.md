# OpenXT für das HP EliteBook 845 G7

Dieser Fork ergänzt OpenXT um Hardware-Unterstützung für das **HP EliteBook
845 G7** (AMD Ryzen PRO 4000 „Renoir“).

- [`meta-openxt-elitebook-845g7/`](meta-openxt-elitebook-845g7) – Yocto-Layer
  mit den Anpassungen (Kernel, Firmware, Boot-Konfiguration, vGlass).
- [`elitebook-845g7/`](elitebook-845g7) – Einrichtungsskript für den
  Build-Workspace sowie Anleitung zu Build, BIOS-Einstellungen, Installation
  und bekannten Einschränkungen.

Gebaut wird der aktuelle OpenXT-Stand (master: Xen 4.21, Linux 6.1, Yocto
dunfell) über [openxt-manifest](https://github.com/OpenXT/openxt-manifest) und
[bordel](https://github.com/OpenXT/bordel); der Layer wird obendrauf gelegt.

## Ursprüngliches Build-System (veraltet)

Die übrigen Dateien in diesem Repository (`do_build.sh`, `build-scripts/`,
…) stammen aus dem Upstream-Repository
[OpenXT/openxt](https://github.com/OpenXT/openxt). Upstream hat sie 2021
eingestellt; sie bauen nur stable-9 und älter und werden für den
845-G7-Build nicht verwendet. Originalhinweis:

> UNMAINTAINED!!!  Please use [bordel](https://github.com/OpenXT/bordel)
>
> This build system only supports stable-9 and earlier.  For xenclient-oe.git as
> of [the merging of vGlass](https://github.com/OpenXT/xenclient-oe/commit/8522fd8c43d57c33cece73a26b4c7498f3d8a58d), see
> [bordel](https://github.com/OpenXT/bordel)
>
> See [the OpenXT wiki](https://github.com/openxt/openxt/wiki) for more
> information. Specifically, see the [How to build OpenXT
> page](https://github.com/OpenXT/openxt/wiki/How-to-build-OpenXT).
