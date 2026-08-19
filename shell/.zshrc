# ~/.zshrc: interaktive Zsh-Konfiguration

[[ -o interactive ]] || return

if [[ -z "${DOTFILES_PROFILE_LOADED:-}" && -r "$HOME/.profile" ]]; then
  source "$HOME/.profile"
fi

HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=200000
setopt append_history
setopt inc_append_history
setopt hist_ignore_dups
setopt hist_ignore_space

if [[ -r "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]]; then
  export ZSH="$HOME/.oh-my-zsh"
  ZSH_THEME=""
  zstyle ':omz:update' mode reminder
  plugins=(git)
  source "$ZSH/oh-my-zsh.sh"
else
  autoload -Uz compinit && compinit
fi

if ls --color=auto -d . >/dev/null 2>&1; then
  alias ls='ls --color=auto'
  alias grep='grep --color=auto'
elif [[ "$(uname -s)" == Darwin ]]; then
  export CLICOLOR=1
  alias ls='ls -G'
fi

[[ -r "$HOME/.config/shell/aliases.sh" ]] && source "$HOME/.config/shell/aliases.sh"
[[ -r "$HOME/.dotfiles/.local/zsh_aliases.sh" ]] && source "$HOME/.dotfiles/.local/zsh_aliases.sh"

command -v starship >/dev/null && eval "$(starship init zsh)"
command -v direnv >/dev/null && eval "$(direnv hook zsh)"
