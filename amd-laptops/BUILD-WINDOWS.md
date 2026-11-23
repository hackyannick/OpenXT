# Installer-ISO unter Windows bauen (WSL2)

Auf einem Windows-Rechner mit x86-CPU läuft der Build nativ, ohne Emulation,
also deutlich schneller als auf einem Mac mit Apple Silicon. Das Skript
[`windows/build-openxt.ps1`](windows/build-openxt.ps1) erledigt alles:

1. legt eine eigene WSL2-Distribution `OpenXT-Build` auf Basis von Ubuntu
   20.04 an (dem offiziell unterstützten Build-System für OpenXT/Yocto
   dunfell); deine übrigen WSL-Distributionen bleiben unberührt,
2. installiert dieselben Build-Abhängigkeiten wie das Docker-Image
   ([`docker/install-build-deps.sh`](docker/install-build-deps.sh)),
3. holt dieses Repository und den OpenXT-Quellcode, baut alles und
4. kopiert das fertige ISO nach `Downloads\openxt-installer.iso`.

> **Achtung beim Bauen auf dem Zielgerät:** Der OpenXT-Installer löscht die
> komplette interne SSD. Baust du auf dem Z13 unter Windows und installierst
> danach OpenXT auf demselben Z13, sind Windows und der Build weg. Das ISO
> also vorher auf den USB-Stick schreiben und die Daten sichern, die du noch
> brauchst.

## Voraussetzungen

- Windows 10 22H2 oder Windows 11, Virtualisierung im BIOS an (beim Z13:
  *Security → Virtualization → AMD Virtualization Technology*).
- Rund **200 GB** freier Platz auf dem Laufwerk für `%LOCALAPPDATA%`
  (änderbar mit `-InstallDir`).
- Netzteil angeschlossen. Das Skript verhindert den Standby, solange es
  läuft; das Zuklappen des Deckels kann je nach Energieeinstellung trotzdem
  in den Standby schicken.

### WSL einmalig einrichten

In einer **Administrator**-PowerShell:

```powershell
wsl --install --no-distribution
```

Danach neu starten.

### Mehr Arbeitsspeicher für WSL (empfohlen)

WSL bekommt standardmäßig nur die Hälfte des RAMs. Das Skript wählt die
Parallelität danach (ein Thread pro 2 GB). Mehr RAM heißt also mehr Tempo
und weniger Abbrüche wegen Speichermangel. Datei
`%USERPROFILE%\.wslconfig` anlegen bzw. ergänzen, zum Beispiel für ein Z13
mit 16 GB:

```ini
[wsl2]
memory=12GB
swap=16GB
processors=16
```

Bei 32 GB RAM: `memory=24GB`. Danach `wsl --shutdown` ausführen. Die Datei
gilt für alle WSL-Distributionen.

## Bauen

Das Skript herunterladen (normale PowerShell, kein Administrator nötig):

```powershell
Invoke-WebRequest -UseBasicParsing -OutFile build-openxt.ps1 `
  https://raw.githubusercontent.com/hackyannick/OpenXT/claude/sweet-carson-kvc649/amd-laptops/windows/build-openxt.ps1
powershell -ExecutionPolicy Bypass -File .\build-openxt.ps1
```

Das war's. Beim ersten Lauf dauern Einrichtung und Downloads eine Weile,
danach läuft der eigentliche Build. Am Ende steht der Pfad zum ISO.

**Abgebrochen?** Einfach dasselbe Kommando noch einmal starten. Fertige
Schritte werden übersprungen, BitBake macht dort weiter, wo es aufgehört hat.

### Einzelne Schritte und Optionen

```powershell
.\build-openxt.ps1 -Step setup    # Distribution, Abhängigkeiten, Workspace
.\build-openxt.ps1 -Step fetch    # nur alle Quellen herunterladen (Download-Check)
.\build-openxt.ps1 -Step build    # bauen
.\build-openxt.ps1 -Step iso      # ISO erzeugen und nach Downloads kopieren
.\build-openxt.ps1 -Threads 12    # Parallelität selbst festlegen
```

Den ersten Lauf immer mit `all` (Standard) oder `setup` machen.

### In die Build-Umgebung schauen

```powershell
wsl -d OpenXT-Build
```

öffnet eine Shell als Benutzer `build`. Der Workspace liegt unter
`~/openxt-workspace`, Logs zu einem fehlgeschlagenen Paket nennt BitBake in
der letzten `ERROR:`-Zeile.

## ISO auf den USB-Stick

Mit [Rufus](https://rufus.ie): Stick wählen, ISO wählen, bei der Nachfrage
**„Im DD-Image-Modus schreiben“** nehmen. Nicht den ISO-Modus und **kein
Ventoy**, sonst findet der Installer sein Repository nicht.

## Aufräumen

```powershell
wsl --unregister OpenXT-Build
```

löscht die Build-Umgebung samt aller Build-Daten.

## Wenn etwas schiefgeht

- **„WSL is not installed“:** Den Einrichtungsschritt oben ausführen und
  neu starten.
- **Build bricht mit `Killed` ab:** zu wenig RAM für WSL, siehe `.wslconfig`
  oben, oder mit `-Threads` weniger Parallelität wählen.
- **Download-Fehler (`do_fetch`):** `-Step fetch` erneut ausführen; bleibt
  ein Paket hängen, die Zeilen mit „Failed downloads“ melden.
- Alles Weitere wie in [BUILD-MACOS.md → Wenn etwas schiefgeht](BUILD-MACOS.md#wenn-etwas-schiefgeht).
