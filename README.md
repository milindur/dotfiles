# Dotfiles installieren

`install.sh` richtet die Terminal-Umgebung unter Debian, Ubuntu, WSL und macOS auf Apple Silicon ein. Das Skript kann mehrfach laufen.

## Installation unter macOS

Führe das Skript aus dem geklonten Repository aus:

```bash
cd ~/.dotfiles
./install.sh
```

Das Skript installiert Homebrew, falls `brew` fehlt. Homebrew installiert `stow`, `direnv`, `gh` und `starship`. Unter macOS installiert das Skript außerdem Oh My Zsh. Der unbeaufsichtigte Installer ändert weder die Login-Shell noch die versionierte `.zshrc`. Die plattformunabhängigen Installer richten Herdr, uv, Rust, fnm mit Node.js, pnpm und Bun ein. pi und Codex werden als globale JavaScript-Pakete installiert.

Der Installer verlinkt `.zprofile`, `.zshrc`, `.profile`, `.bashrc`, `.vimrc`, die gemeinsame Git-Konfiguration, die gemeinsamen Aliase und das Verzeichnis `.pandoc/defaults` mit GNU Stow. Er verschiebt vorhandene Dateien und Verzeichnisse in Sicherungen wie `.zshrc.pre-stow` oder `defaults.pre-stow`. Öffne nach der Installation ein neues Terminal.

## Pandoc-Defaults

Pandoc-Defaults liegen unter `pandoc/.pandoc/defaults/`. Lege weitere YAML-Dateien in diesem Verzeichnis ab; durch den Stow-Link sind sie zugleich unter `~/.pandoc/defaults/` verfügbar.

## API-Keys (sops + age)

API-Keys liegen verschlüsselt im Repo unter `secrets/` als dotenv-Dateien, eine je Umgebung: `pc.env` (privater PC), `mac.env`, `work.env` (Firmen-Laptop), dazu `private.env` für alle privaten Rechner und `common.env` für alle inklusive Firmen-Laptop. sops verschlüsselt nur die Werte; welche Variablen es gibt, bleibt im Diff sichtbar.

Jeder Rechner hat einen eigenen age-Schlüssel unter `~/.config/sops/age/keys.txt`. `install.sh` erzeugt ihn beim ersten Lauf und gibt den Public Key aus. Der private Schlüssel verlässt den Rechner nie; ohne ihn sind die Dateien wertlos.

Die Weiche ist `.local/secrets-env` (nicht versioniert): eine Zeile mit dem Umgebungsnamen, z.B. `pc`. `.profile` entschlüsselt beim Login `common.env`, bei `pc` und `mac` zusätzlich `private.env` und zuletzt `<umgebung>.env` und exportiert die Variablen. Fehlt sops, der Schlüssel oder die Weiche, startet die Shell normal, nur ohne Keys.

Bearbeiten (öffnet den Editor mit Klartext, verschlüsselt beim Speichern):

```bash
sops secrets/pc.env
```

Neuen Rechner aufnehmen:

1. `./install.sh` ausführen, ausgegebenen Public Key kopieren.
2. Public Key in `.sops.yaml` als Anker ergänzen und in die Regeln der Dateien eintragen, die der Rechner lesen soll.
3. Auf einem bereits berechtigten Rechner `sops updatekeys secrets/<datei>.env` ausführen und committen.
4. Auf dem neuen Rechner `.local/secrets-env` anlegen.

Eine Datei kann nur bearbeiten, wessen Schlüssel als Empfänger eingetragen ist. `work.env` ist daher bewusst nur für den Firmen-Laptop lesbar, private Keys bleiben dem Firmengerät verborgen und umgekehrt.

## Git-Identität

Die versionierte Git-Konfiguration liegt unter `git/.config/git/config`. Sie enthält gemeinsame Einstellungen und den Namen, aber keine E-Mail-Adresse und keine Credential-Helper. Git lädt zusätzlich die rechnerlokale Datei `~/.gitconfig`.

Auf dem Firmen-Laptop reicht die Firmenadresse als Standard:

```gitconfig
[user]
    email = vorname.nachname@firma.example
```

Auf privaten Geräten bleibt die private Adresse der Standard. Eine bedingte Konfiguration wählt für alle Repositories unter `~/work/` die Firmenadresse:

```gitconfig
# ~/.gitconfig
[user]
    email = privat@example.net

[includeIf "gitdir:~/work/"]
    path = ~/.gitconfig-work
```

```gitconfig
# ~/.gitconfig-work
[user]
    email = vorname.nachname@firma.example
```

Passe `~/work/` an das Verzeichnis deiner Firmen-Repositories an. Git wendet die Regel auch auf Unterverzeichnisse an. Für einen einzelnen Sonderfall überschreibt `git config user.email vorname.nachname@firma.example` die globale Auswahl nur im aktuellen Repository. Mit `git config user.email` prüfst du vor dem ersten Commit die wirksame Adresse. `user.useConfigOnly = true` verhindert, dass Git bei fehlender Adresse eine automatisch abgeleitete Identität verwendet.

## Lokale Werte übernehmen

Speichere Schlüssel und rechnerabhängige Einstellungen in `.local/profile.sh`. Git ignoriert dieses Verzeichnis. Kopiere auf dem Mac zum Beispiel die nötigen `export`-Zeilen aus `.zprofile.pre-stow`:

```bash
mkdir -p ~/.dotfiles/.local
${EDITOR:-vi} ~/.dotfiles/.local/profile.sh
chmod 600 ~/.dotfiles/.local/profile.sh
```

Die Shell-Konfiguration lädt diese Datei vor den LiteLLM-Standardwerten. Ein lokaler Wert für `ANTHROPIC_BASE_URL` oder `ANTHROPIC_CUSTOM_HEADERS` bleibt deshalb erhalten.

## Gemeinsame Shell-Konfiguration

Bash und Zsh laden die Aliase aus `.config/shell/aliases.sh`. Dazu gehören `ll`, `la`, `l` sowie die Startoptionen für Claude und Codex. Die Shell aktiviert `starship` und `direnv`, wenn das jeweilige Programm verfügbar ist.

Lege zusätzliche, nicht versionierte Aliase in `.local/bash_aliases.sh` oder `.local/zsh_aliases.sh` ab. Die Zsh-Konfiguration bindet OrbStack und den LM-Studio-Pfad nur ein, wenn die Programme auf dem Rechner vorhanden sind. Oh My Zsh lädt das Git-Plugin. Starship übernimmt den Prompt, deshalb bleibt `ZSH_THEME` leer. Falls Oh My Zsh fehlt, verwendet die Konfiguration die native Zsh-Completion.

Das Skript installiert Claude Code nicht. Ein bereits installiertes `claude` verwendet den gemeinsamen Alias.
