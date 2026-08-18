#!/usr/bin/env bash
# Bootstrap: installiert benötigte Tools und richtet Symlinks via stow ein.
# Idempotent, für Debian/Ubuntu/WSL. Aufruf: ./install.sh
set -euo pipefail
cd "$(dirname "$0")"

# --- apt-Basis: stow + direnv (apt-Version reicht) ---
need_apt=()
command -v stow   >/dev/null || need_apt+=(stow)
command -v direnv >/dev/null || need_apt+=(direnv)
command -v curl   >/dev/null || need_apt+=(curl)
if [ ${#need_apt[@]} -gt 0 ]; then
    sudo apt-get update
    sudo apt-get install -y "${need_apt[@]}"
fi

# --- starship: Binary nach ~/.local/bin, fasst keine Configs an ---
if ! command -v starship >/dev/null; then
    mkdir -p "$HOME/.local/bin"
    curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"
fi

# --- herdr: Agent-Multiplexer, Einzel-Binary nach ~/.local/bin ---
if ! command -v herdr >/dev/null; then
    curl -fsSL https://herdr.dev/install.sh | sh
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

# --- stow: Symlinks für alle Pakete (aktuell nur shell/) ---
# vorhandene echte Dateien wegsichern, sonst verweigert stow den Link
for f in .bashrc .profile; do
    if [ -f "$HOME/$f" ] && [ ! -L "$HOME/$f" ]; then
        mv "$HOME/$f" "$HOME/$f.pre-stow"
    fi
done
stow -R -t "$HOME" shell

# bun-Installer hängt ggf. eine Completion-Zeile an die (jetzt symlinkte)
# .bashrc an -> nur warnen, nicht automatisch verwerfen
if ! git diff --quiet -- shell/.bashrc 2>/dev/null; then
    echo "Hinweis: shell/.bashrc wurde veraendert (vermutlich bun-Installer)."
    echo "Pruefen mit: git diff shell/.bashrc"
fi

echo "Fertig. Neu einloggen oder: source ~/.profile"
