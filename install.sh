#!/usr/bin/env bash
# Bootstrap: installiert benoetigte Tools und richtet Symlinks via stow ein.
# Idempotent, fuer Debian/Ubuntu/WSL und macOS. Aufruf: ./install.sh
set -euo pipefail
cd "$(dirname "$0")"

# --- Plattformpakete ---
case "$(uname -s)" in
    Linux)
        if ! command -v apt-get >/dev/null; then
            echo "Nicht unterstuetzte Linux-Distribution: apt-get fehlt." >&2
            exit 1
        fi

        need_apt=()
        command -v stow   >/dev/null || need_apt+=(stow)
        command -v direnv >/dev/null || need_apt+=(direnv)
        command -v curl   >/dev/null || need_apt+=(curl)
        if [ ${#need_apt[@]} -gt 0 ]; then
            sudo apt-get update
            sudo apt-get install -y "${need_apt[@]}"
        fi

        # Das Ubuntu-Paket von gh ist oft deutlich veraltet.
        if ! command -v gh >/dev/null; then
            sudo mkdir -p -m 755 /etc/apt/keyrings
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
                | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
            sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
                | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
            sudo apt-get update
            sudo apt-get install -y gh
        fi

        # Binary nach ~/.local/bin, fasst keine Configs an.
        if ! command -v starship >/dev/null; then
            mkdir -p "$HOME/.local/bin"
            curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"
        fi
        ;;
    Darwin)
        if [ "$(uname -m)" != arm64 ]; then
            echo "Nicht unterstuetzte Mac-Architektur: $(uname -m)" >&2
            exit 1
        fi

        if ! command -v brew >/dev/null; then
            echo "Homebrew wird installiert."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi

        if command -v brew >/dev/null; then
            brew_bin="$(command -v brew)"
        elif [ -x /opt/homebrew/bin/brew ]; then
            brew_bin=/opt/homebrew/bin/brew
        else
            echo "Homebrew wurde installiert, aber brew wurde nicht gefunden." >&2
            exit 1
        fi
        eval "$("$brew_bin" shellenv)"

        need_brew=()
        command -v stow     >/dev/null || need_brew+=(stow)
        command -v direnv   >/dev/null || need_brew+=(direnv)
        command -v gh       >/dev/null || need_brew+=(gh)
        command -v starship >/dev/null || need_brew+=(starship)
        if [ ${#need_brew[@]} -gt 0 ]; then
            brew install "${need_brew[@]}"
        fi

        ;;
    *)
        echo "Nicht unterstuetztes Betriebssystem: $(uname -s)" >&2
        exit 1
        ;;
esac

# --- herdr: Agent-Multiplexer, Einzel-Binary nach ~/.local/bin ---
if ! command -v herdr >/dev/null; then
    curl -fsSL https://herdr.dev/install.sh | sh
fi

# --- uv: Python-Paketmanager, Binary nach ~/.local/bin ---
if ! command -v uv >/dev/null; then
    curl -LsSf https://astral.sh/uv/install.sh | env INSTALLER_NO_MODIFY_PATH=1 sh
fi

# --- rustup/cargo: --no-modify-path, .profile sourced ~/.cargo/env selbst ---
if [ ! -x "$HOME/.cargo/bin/cargo" ]; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
        | sh -s -- -y --no-modify-path
fi

# --- fnm: --skip-shell, Zielpfad passt zu .profile ---
if [ ! -d "$HOME/.local/share/fnm" ]; then
    curl -fsSL https://fnm.vercel.app/install \
        | bash -s -- --install-dir "$HOME/.local/share/fnm" --skip-shell
fi

# --- Node via fnm, pnpm via corepack (kein Shell-Config-Gefummel) ---
export PATH="$HOME/.local/share/fnm:$PATH"
eval "$(fnm env --shell bash)"
fnm install --lts
command -v pnpm >/dev/null || corepack enable pnpm

# --- bun: BUN_INSTALL ist in .profile schon gesetzt ---
if [ ! -x "$HOME/.bun/bin/bun" ]; then
    curl -fsSL https://bun.sh/install | bash
fi

# --- Agent-CLIs: pi + codex ---
# beide bewusst nicht ueber ihre curl-Installer (chatgpt.com ist in der
# Firmen-Firewall geblockt); die npm-Pakete ziehen das Plattform-Binary als
# optionale Dependency. Pruefung jeweils auf den Ziel-Bin statt auf $PATH:
# npm-globale Installationen haengen an der aktiven fnm-Node-Version und
# wuerden hier faelschlich als "da" gelten.
export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME/bin:$PATH"
[ -x "$PNPM_HOME/bin/pi" ] || pnpm add -g --ignore-scripts @earendil-works/pi-coding-agent

# codex via bun, nicht via pnpm: pnpm v11 sperrt Versionen die ersten 24h nach
# Release (minimumReleaseAge). Codex released fast taeglich und startet bei
# Versionsrueckstand seinen Selbst-Updater -> pnpm liefert wieder die alte
# Version -> Endlosschleife. bun kennt diese Sperre nicht.
[ -x "$HOME/.bun/bin/codex" ] || "$HOME/.bun/bin/bun" add -g @openai/codex

# --- stow: Symlinks fuer alle Konfigurationspakete ---
# Vorhandene Dateien und fremde Symlinks sichern, sonst verweigert stow den Link.
for source in \
    git/.config/git/config \
    pandoc/.pandoc/defaults \
    shell/.bashrc \
    shell/.profile \
    shell/.zprofile \
    shell/.zshrc \
    vim/.vimrc; do
    target=${source#*/}
    if { [ -e "$HOME/$target" ] || [ -L "$HOME/$target" ]; } \
        && ! [ "$HOME/$target" -ef "$PWD/$source" ]; then
        backup="$HOME/$target.pre-stow"
        suffix=1
        while [ -e "$backup" ]; do
            backup="$HOME/$target.pre-stow.$suffix"
            suffix=$((suffix + 1))
        done
        mv "$HOME/$target" "$backup"
        echo "$HOME/$target gesichert als $backup"
    fi
done
stow -R -t "$HOME" git shell vim pandoc

# Oh My Zsh erst nach stow installieren. So findet der Installer bereits die
# versionierte .zshrc und legt keine eigene Konfiguration an.
if [ "$(uname -s)" = Darwin ] && [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
        "" --unattended --keep-zshrc
fi

# bun-Installer haengt ggf. eine Completion-Zeile an eine Shell-Konfiguration.
# Nur warnen, nicht automatisch verwerfen.
if ! git diff --quiet -- shell/.bashrc shell/.zshrc 2>/dev/null; then
    echo "Hinweis: Eine Shell-Konfiguration wurde veraendert (vermutlich bun-Installer)."
    echo "Pruefen mit: git diff -- shell/.bashrc shell/.zshrc"
fi

echo "Fertig. Terminal neu oeffnen oder das passende Profil laden:"
echo "  Bash: source ~/.profile"
echo "  Zsh:  source ~/.zprofile && source ~/.zshrc"
