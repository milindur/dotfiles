# ~/.bashrc: executed by bash for non-login shells

# If not running interactively, don't do anything
case $- in
  *i*) ;;
  *) return;;
esac

# don't put duplicate lines or lines starting with space in the history
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# write history after each command, not only on shell exit
PROMPT_COMMAND='history -a'

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=100000
HISTFILESIZE=200000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories
shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
  test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
  alias ls='ls --color=auto'
  alias dir='dir --color=auto'
  alias vdir='vdir --color=auto'

  alias grep='grep --color=auto'
  alias fgrep='fgrep --color=auto'
  alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# enable programmable completion features
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

if [ -r "$HOME/.dotfiles/.local/bash_aliases.sh" ]; then
  source "$HOME/.dotfiles/.local/bash_aliases.sh"
fi

[ -r "$HOME/.config/shell/aliases.sh" ] && . "$HOME/.config/shell/aliases.sh"

# bun drops its bash completion into the first existing directory of its
# candidate list; ~/.bash_completion.d is the portable one, but neither bash nor
# the bash-completion package sources that directory on its own. Unlike the zsh
# path, bun never appends anything to this file.
if [ -d "$HOME/.bash_completion.d" ]; then
  for _completion in "$HOME"/.bash_completion.d/*.bash; do
    [ -r "$_completion" ] && . "$_completion"
  done
  unset _completion
fi

command -v starship >/dev/null && eval "$(starship init bash)"
command -v direnv >/dev/null && eval "$(direnv hook bash)"
