# Laedt sops/age-verschluesselte API-Keys aus dem Dotfiles-Repo.
# Die Weiche ist ~/.dotfiles/.local/secrets-env: eine Zeile mit dem
# Umgebungsnamen (pc, mac oder work). Geladen werden secrets/common.env
# (falls vorhanden), auf privaten Umgebungen secrets/private.env und
# zuletzt secrets/<umgebung>.env. Ohne sops, ohne age-Schluessel oder
# ohne Weiche passiert nichts.
dotfiles_load_secrets() {
  _dotfiles="$HOME/.dotfiles"

  # Einheitlicher Schluesselpfad; ohne den Export sucht sops unter macOS
  # in ~/Library/Application Support statt in ~/.config.
  export SOPS_AGE_KEY_FILE="${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}"

  command -v sops >/dev/null 2>&1 || return 0
  [ -r "$SOPS_AGE_KEY_FILE" ] || return 0

  if [ ! -r "$_dotfiles/.local/secrets-env" ]; then
    echo "Hinweis: $_dotfiles/.local/secrets-env fehlt (Inhalt: pc, mac oder work). Keine API-Keys geladen." >&2
    return 0
  fi
  read -r _secrets_env < "$_dotfiles/.local/secrets-env"

  # private.env teilen sich die privaten Umgebungen; work kann sie
  # ohnehin nicht entschluesseln, also gar nicht erst versuchen.
  _secrets_private=""
  case "$_secrets_env" in
    pc|mac) _secrets_private="$_dotfiles/secrets/private.env" ;;
  esac

  for _secrets_file in "$_dotfiles/secrets/common.env" $_secrets_private "$_dotfiles/secrets/$_secrets_env.env"; do
    [ -f "$_secrets_file" ] || continue
    if _secrets_plain="$(sops -d "$_secrets_file" 2>/dev/null)"; then
      set -a
      eval "$_secrets_plain"
      set +a
    else
      echo "Warnung: $_secrets_file liess sich nicht entschluesseln." >&2
    fi
  done
}
dotfiles_load_secrets
unset -f dotfiles_load_secrets
unset _dotfiles _secrets_env _secrets_private _secrets_file _secrets_plain
