# ~/.profile: executed by the command interpreter for login shells

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

export COLORTERM=truecolor
export VISUAL="code --wait"
export CPM_SOURCE_CACHE="$HOME/.cache/CPM"

# bun
export BUN_INSTALL="$HOME/.bun"
case ":$PATH:" in
  *":$BUN_INSTALL/bin:"*) ;;
  *) export PATH="$BUN_INSTALL/bin:$PATH" ;;
esac

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
# pnpm end

# fnm
FNM_PATH="/home/christian/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  case ":$PATH:" in
    *":$FNM_PATH:"*) ;;
    *) export PATH="$FNM_PATH:$PATH" ;;
  esac
  eval "$(fnm env --shell bash)"
fi

[ -r "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
[ -r "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
  PATH="$HOME/bin:$PATH"
fi
if [ -d "$HOME/.local/bin" ] ; then
  PATH="$HOME/.local/bin:$PATH"
fi

if [ -r "$HOME/.dotfiles/.local/profile.sh" ]; then
  . "$HOME/.dotfiles/.local/profile.sh"
fi

if [ -n "$LITELLM_CLAUDE_KEY" ]; then
  export ANTHROPIC_BASE_URL="https://litellm.piranha-banfish.ts.net"
  export ANTHROPIC_CUSTOM_HEADERS="x-litellm-api-key: $LITELLM_CLAUDE_KEY"
fi

# if running bash
if [ -n "$BASH_VERSION" ]; then
  # include .bashrc if it exists
  if [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
  fi
fi
