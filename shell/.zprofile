# ~/.zprofile: Umgebung fuer Zsh-Login-Shells

[ -r "$HOME/.profile" ] && . "$HOME/.profile"

# OrbStack ergaenzt seine CLI und SSH-Integration, wenn es installiert ist.
[ -r "$HOME/.orbstack/shell/init.zsh" ] && source "$HOME/.orbstack/shell/init.zsh"
