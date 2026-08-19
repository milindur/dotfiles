# Dotfiles installieren

`install.sh` richtet die Terminal-Umgebung unter Debian, Ubuntu, WSL und macOS auf Apple Silicon ein. Das Skript kann mehrfach laufen.

## Installation unter macOS

Führe das Skript aus dem geklonten Repository aus:

```bash
cd ~/.dotfiles
./install.sh
```

Das Skript installiert Homebrew, falls `brew` fehlt. Homebrew installiert `stow`, `direnv`, `gh` und `starship`. Unter macOS installiert das Skript außerdem Oh My Zsh. Der unbeaufsichtigte Installer ändert weder die Login-Shell noch die versionierte `.zshrc`. Die plattformunabhängigen Installer richten Herdr, uv, Rust, fnm mit Node.js, pnpm und Bun ein. pi und Codex werden als globale JavaScript-Pakete installiert.

Der Installer verlinkt `.zprofile`, `.zshrc`, `.profile`, `.bashrc` und die gemeinsamen Aliase mit GNU Stow. Er verschiebt vorhandene Shell-Dateien in Sicherungen wie `.zshrc.pre-stow`. Öffne nach der Installation ein neues Terminal.

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
