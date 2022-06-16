# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"

plugins+=(git zsh-completions zsh-autosuggestions zsh-syntax-highlighting)
autoload -U compinit && compinit

source $ZSH/oh-my-zsh.sh

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
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

if [[ $(command -v thefuck) ]]; then
  eval $(thefuck --alias)
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

if [[ $(command -v vim) ]]; then
  export EDITOR=vim
fi
