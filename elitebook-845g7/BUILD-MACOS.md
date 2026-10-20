# Installer-ISO auf einem Mac mit Apple Silicon (M1–M4) bauen

OpenXT wird mit Yocto (dunfell) gebaut, und das läuft nur auf **x86_64-Linux**.
Auf einem Apple-Silicon-Mac geht das über einen x86_64-Docker-Container, den
macOS mit **Rosetta** ausführt. Alternativ mietest du für die Bauzeit einen
x86-Server; die Befehle sind in beiden Fällen dieselben.

| | Mac lokal (Rosetta) | x86-Server in der Cloud |
|---|---|---|
| Kosten | keine | Stundenmiete, nach dem Build löschen |
| Dauer | lang, weil jeder Compiler emuliert wird | deutlich kürzer bei 16+ echten Kernen |
| Speicher | ~200 GB frei auf dem Mac (Docker-Disk) | Server mit ≥ 300 GB Disk wählen |
| Nebenwirkung | Mac ist stundenlang ausgelastet | keine |

Grobe Zahlen, nicht gemessen: Ein OpenXT-Komplettbuild braucht auf einer
schnellen x86-Maschine mehrere Stunden. Unter Rosetta kann es ein Mehrfaches
davon sein. Spätere Builds sind dank Cache viel schneller.

---

## Variante A: lokal auf dem Mac

### 1. Docker-Umgebung installieren

Empfohlen ist [OrbStack](https://orbstack.dev) (schneller als Docker Desktop
und nutzt Rosetta automatisch):

```bash
brew install orbstack
open -a OrbStack
```

In den OrbStack-Einstellungen prüfen:

- **System → Use Rosetta to run Intel code**: an
- **System → Memory limit**: großzügig, z. B. 24 GB bei 32 GB RAM, 12 GB bei
  16 GB RAM

Mit Docker Desktop geht es auch. Dort unter *Settings → General* „Use
Rosetta for x86_64/amd64 emulation“ einschalten, und unter *Resources* das
**Disk-Limit auf mindestens 250 GB** erhöhen (Standard sind 64 GB, das reicht
nicht) sowie den Speicher erhöhen.

### 2. Repository holen und Build-Image erzeugen

```bash
git clone -b claude/sweet-carson-kvc649 https://github.com/hackyannick/OpenXT.git
cd OpenXT
docker build --platform linux/amd64 -t openxt-builder elitebook-845g7/docker
```

Das Image enthält alle Build-Abhängigkeiten, GHC 8.10.7 (für die
Haskell-Teile von OpenXT) und `repo`.

> Sobald der Branch nach `main` gemerged ist, `-b claude/sweet-carson-kvc649`
> weglassen.

### 3. Build-Container starten

Der gesamte Workspace liegt in einem **Docker-Volume**, nicht in einem
macOS-Ordner. Das ist wichtig: macOS-Dateisysteme unterscheiden standardmäßig
keine Groß-/Kleinschreibung, und Yocto bricht darauf ab. Außerdem wäre ein
gemounteter Mac-Ordner sehr langsam.

```bash
docker volume create openxt-ws
docker run --platform linux/amd64 -it --name openxt \
    --security-opt seccomp=unconfined \
    -v openxt-ws:/work \
    openxt-builder
```

Du bist jetzt im Container (Prompt `build@…:/work$`). Alle weiteren Schritte
bis einschließlich 6 laufen dort.

### 4. Workspace einrichten (im Container)

```bash
git config --global user.name  "Dein Name"
git config --global user.email "du@example.org"

git clone -b claude/sweet-carson-kvc649 https://github.com/hackyannick/OpenXT.git /work/OpenXT

# Parallelität an den RAM anpassen: etwa 1 Thread pro 2 GB, die Docker hat
OPENXT_THREADS=8 /work/OpenXT/elitebook-845g7/setup-workspace.sh /work
```

Das Skript lädt per `repo` alle OpenXT-Quellen (master), legt mit `bordel`
den Build `build-845g7` an und trägt den 845-G7-Layer ein. Eine Frage von
`repo` nach Farbausgabe kannst du mit Enter beantworten.

### 5. Bauen (im Container)

```bash
cd /work
openxt/bordel/bordel -i 845g7 certs create all
openxt/bordel/bordel -i 845g7 build
```

- `certs create all` erzeugt Test-Zertifikate zum Signieren der
  Kernel-Module und des Update-Repositorys. Das ist für den Eigenbedarf
  richtig so.
- `build` baut nacheinander alle Images (Installer, dom0, UIVM, NDVM, …).
  Läuft er auf einen Fehler, kannst du denselben Befehl einfach erneut
  starten; Fertiges wird nicht noch einmal gebaut.
- Den Mac in dieser Zeit nicht schlafen lassen: in einem zweiten
  Terminal-Fenster `caffeinate -i` laufen lassen.

### 6. ISO erzeugen (im Container)

```bash
openxt/bordel/bordel -i 845g7 deploy iso
```

Am Ende steht der Pfad, normalerweise
`/work/build-845g7/deploy/openxt-installer.iso`. Mit `exit` verlässt du den
Container.

### 7. ISO auf den Mac holen

In einem normalen macOS-Terminal:

```bash
docker cp openxt:/work/build-845g7/deploy/openxt-installer.iso ~/Downloads/
```

Später weiterarbeiten (z. B. nach einem Update des Layers):

```bash
docker start -ai openxt
cd /work/OpenXT && git pull
cd /work && openxt/bordel/bordel -i 845g7 build && openxt/bordel/bordel -i 845g7 deploy iso
```

---

## Variante B: x86-Server in der Cloud

Einen Linux-Server mit **x86_64**, 16+ Kernen, 32–64 GB RAM und mindestens
300 GB Disk mieten (z. B. bei Hetzner, AWS oder Google Cloud), Ubuntu oder
Debian als System. Dann:

```bash
ssh root@<server>
apt-get update && apt-get install -y docker.io git tmux
tmux          # damit der Build weiterläuft, wenn die SSH-Verbindung abbricht

git clone -b claude/sweet-carson-kvc649 https://github.com/hackyannick/OpenXT.git
cd OpenXT
docker build -t openxt-builder elitebook-845g7/docker
docker volume create openxt-ws
docker run -it --name openxt --security-opt seccomp=unconfined \
    -v openxt-ws:/work openxt-builder
```

Danach im Container die Schritte **4 bis 6** von oben ausführen, bei
`OPENXT_THREADS` die Kernzahl des Servers eintragen. Anschließend auf dem
Server `docker cp openxt:/work/build-845g7/deploy/openxt-installer.iso .`
und vom Mac aus:

```bash
scp root@<server>:OpenXT/openxt-installer.iso ~/Downloads/
```

Server danach löschen, sonst läuft die Miete weiter.

---

## ISO auf einen USB-Stick schreiben (macOS)

**Achtung: Der Stick wird komplett überschrieben. Die richtige Disk-Nummer
prüfen, eine falsche Nummer löscht die falsche Platte.**

```bash
diskutil list                      # Stick suchen, z. B. /dev/disk4 (external, physical)
diskutil unmountDisk /dev/disk4
sudo dd if=~/Downloads/openxt-installer.iso of=/dev/rdisk4 bs=4m status=progress
diskutil eject /dev/disk4
```

`rdisk` statt `disk` ist absichtlich, das ist auf macOS viel schneller.
Meldet macOS danach „Das eingesetzte Volume kann nicht gelesen werden“, ist
das normal, einfach auf „Auswerfen“ klicken.

Installation und BIOS-Einstellungen am EliteBook: siehe [README.md](README.md).

---

## Wenn etwas schiefgeht

- **`docker build` meldet `403 Forbidden: all proposed auth schemes denied`
  oder `429 Too Many Requests` für `docker.io/library/ubuntu`:** Docker schickt
  ungültige Docker-Hub-Zugangsdaten mit (häufig ein Rest von Docker Desktop),
  oder Docker Hub begrenzt die Downloads. Abhilfe:
  1. `docker logout` ausführen und in `~/.docker/config.json` einen Eintrag
     `"credsStore": "desktop"` entfernen, falls vorhanden. Danach mit
     `docker pull hello-world` testen.
  2. Oder Docker Hub ganz umgehen und das Basis-Image von Googles Mirror holen:
     ```bash
     docker build --platform linux/amd64 \
         --build-arg BASE_IMAGE=mirror.gcr.io/library/ubuntu:20.04 \
         -t openxt-builder elitebook-845g7/docker
     ```
- **`docker build` schlägt bei GHC oder `repo` fehl:** Download-Problem, den
  Befehl wiederholen.
- **Build bricht mit „No space left on device“ ab:** Docker-Disk-Limit
  erhöhen (Docker Desktop) bzw. Platz auf dem Mac schaffen. Mit
  `docker system df` siehst du den Verbrauch.
- **Build bricht mit „Killed“ oder OOM ab:** `OPENXT_THREADS` verkleinern. Den
  Wert in `/work/build-845g7/conf/local.conf` anpassen (unten stehen
  `BB_NUMBER_THREADS` und `PARALLEL_MAKE`).
- **Downloads scheitern** (`do_fetch` failed): Ein Teil der Quellen kommt vom
  OpenXT-Mirror `openxt.ainfosec.com`. Ist der nicht erreichbar, den Build
  später erneut starten. Hält der Fehler an, Log aus
  `/work/build-845g7/tmp-glibc/work/…/temp/log.do_fetch` sichern.
- **Einzelnes Paket schlägt fehl:** Die letzte Zeile mit `ERROR:` nennt
  Rezept und Logdatei. Die Logdatei ist der Ausgangspunkt zur Fehlersuche.
