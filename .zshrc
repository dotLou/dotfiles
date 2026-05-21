# === PATH SETUP (order matters: later = higher priority) ===
# Homebrew (lowest priority)
[[ -x /opt/homebrew/bin/brew ]] && eval $(/opt/homebrew/bin/brew shellenv)

export PATH="$HOME/.local/bin:$PATH" # add local bin, so native installs (like claude) are in the path

# NVM (low-medium priority — shadowenv overrides this per-project)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Nix (medium priority)
if [ -e $HOME/.nix-profile/etc/profile.d/nix.sh ]; then
  . $HOME/.nix-profile/etc/profile.d/nix.sh
fi

# tec profile (highest priority - must come last)
[[ -x /Users/louiscloutier/.local/state/tec/profiles/base/current/global/init ]] && eval "$(/Users/louiscloutier/.local/state/tec/profiles/base/current/global/init zsh)"

# === PROMPT THEME TOGGLE ===
# Set PROMPT_THEME to "starship" or "p10k" (default: starship)
# Override in ~/.zshenv or export before shell init to switch.
export PROMPT_THEME="${PROMPT_THEME:-starship}"

use-starship() { export PROMPT_THEME=starship; exec zsh; }
use-p10k()     { export PROMPT_THEME=p10k;     exec zsh; }

if [[ "$PROMPT_THEME" == "p10k" ]]; then
  # Enable Powerlevel10k instant prompt.
  if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
  fi

  export ZSH="$HOME/.oh-my-zsh"
  ZSH_THEME="powerlevel10k/powerlevel10k"
  plugins+=(git zsh-completions zsh-autosuggestions zsh-syntax-highlighting)
  autoload -U compinit && compinit
  source $ZSH/oh-my-zsh.sh
else
  # Starship — load oh-my-zsh without a theme, then init starship
  export ZSH="$HOME/.oh-my-zsh"
  ZSH_THEME=""
  plugins+=(git zsh-completions zsh-autosuggestions zsh-syntax-highlighting)
  autoload -U compinit && compinit
  source $ZSH/oh-my-zsh.sh
  eval "$(starship init zsh)"
fi

# User configuration

# Fix slowness of pastes with zsh-syntax-highlighting.zsh
# From https://gist.github.com/magicdude4eva/2d4748f8ef3e6bf7b1591964c201c1ab
pasteinit() {
  OLD_SELF_INSERT=${${(s.:.)widgets[self-insert]}[2,3]}
  zle -N self-insert url-quote-magic
}

pastefinish() {
  zle -N self-insert $OLD_SELF_INSERT
}
zstyle :bracketed-paste-magic paste-init pasteinit
zstyle :bracketed-paste-magic paste-finish pastefinish

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
if [[ "$PROMPT_THEME" == "p10k" ]]; then
  [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
fi

if [[ $(command -v thefuck) ]]; then
  eval $(thefuck --alias)
fi

if [[ $(command -v gt) ]]; then
  source <(gt completion)
fi

if [[ $(command -v spin) ]]; then
  source <(spin completion)
fi

if [[ $(command -v journalctl) ]]; then
  alias jc=journalctl
fi

if [[ $(command -v systemctl) ]]; then
  alias sc=systemctl
fi

if [[ $(command -v wls) ]]; then
  alias ls=wls
fi

# if $HOME/zsh_extras directory exists, source all files in $HOME/zsh_extras if any exist
if [[ -d $HOME/zsh_extras ]]; then
  # return early if no files exist
  if [[ ! "$(ls -A $HOME/zsh_extras)" ]]; then
    return
  fi
  for file in $HOME/zsh_extras/*.sh; do
    if [[ -f $file ]]; then
      source $file
    fi
  done
fi

if [[ $(command -v nvim) ]]; then
  export EDITOR="nvim"
  export VISUAL="nvim"
elif [[ $(command -v vim) ]]; then
  export EDITOR="vim"
  export VISUAL="vim"
fi

[[ -f /opt/dev/sh/chruby/chruby.sh ]] && { type chruby >/dev/null 2>&1 || chruby () { source /opt/dev/sh/chruby/chruby.sh; chruby "$@"; } }

[ -f /opt/dev/dev.sh ] && source /opt/dev/dev.sh

# cloudplatform: add Shopify clusters to your local kubernetes config
export KUBECONFIG=${KUBECONFIG:+$KUBECONFIG:}/Users/louiscloutier/.kube/config:/Users/louiscloutier/.kube/config.shopify.cloudplatform
for file in /Users/louiscloutier/src/github.com/Shopify/cloudplatform/workflow-utils/*.bash; do source ${file}; done
kubectl-short-aliases

## Fix ghostty pathing issues, from https://vault.shopify.io/posts/382372-Ghostty-splits-opening-in-the-wrong-World-worktree-Copy-this-script
if [[ -n ${GHOSTTY_RESOURCES_DIR:-} ]]; then
  source "$GHOSTTY_RESOURCES_DIR/shell-integration/zsh/ghostty-integration"

  _ghostty_report_pwd_with_local_hostname() {
    builtin emulate -L zsh -o no_aliases

    [[ ${TERM_PROGRAM:-} == ghostty ]] || return 0

    local local_hostname
    local_hostname=$(command hostname 2>/dev/null) || return 0

    if (( ${+_ghostty_fd} )); then
      builtin print -rnu $_ghostty_fd -- $'\e]7;file://'"${local_hostname}${PWD}"$'\a'
    else
      builtin print -rn -- $'\e]7;file://'"${local_hostname}${PWD}"$'\a'
    fi

    precmd_functions=(${precmd_functions:#_ghostty_report_pwd_with_local_hostname} _ghostty_report_pwd_with_local_hostname)
    chpwd_functions=(${chpwd_functions:#_ghostty_report_pwd_with_local_hostname} _ghostty_report_pwd_with_local_hostname)
  }

  precmd_functions=(${precmd_functions:#_ghostty_report_pwd_with_local_hostname} _ghostty_report_pwd_with_local_hostname)
  chpwd_functions=(${chpwd_functions:#_ghostty_report_pwd_with_local_hostname} _ghostty_report_pwd_with_local_hostname)
fi
