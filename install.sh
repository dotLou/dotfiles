#!/bin/bash

# This script is safe to run multiple times. It installs anything that is
# missing and updates anything already present, skips OMZ (which auto-updates
# itself), and never clobbers an existing backup.

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES_DIR" || exit 1

# --- helpers -----------------------------------------------------------------

# link_dotfile <source> <dest>
# Idempotently symlink <dest> -> <source>.
#   - If <dest> already points at <source>, do nothing.
#   - If <dest> exists and is something else, back it up first.
#   - An existing backup is never overwritten (a timestamped name is used).
link_dotfile() {
  local source="$1" dest="$2" backup

  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$source" ]; then
    echo "  $dest already linked"
    return 0
  fi

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    backup="${dest}.backup-before-dotfiles"
    if [ -e "$backup" ] || [ -L "$backup" ]; then
      backup="${backup}.$(date +%Y%m%d%H%M%S)"
    fi
    mv "$dest" "$backup"
    echo "  Backed up existing $dest to $backup"
  fi

  ln -s "$source" "$dest"
}

# clone_or_update <url> <dest> [extra git clone args...]
# Clone <dest> if missing, otherwise pull the latest changes.
clone_or_update() {
  local url="$1" dest="$2"
  shift 2
  if [ -d "$dest/.git" ]; then
    echo "  Updating $dest"
    git -C "$dest" pull --ff-only || echo "  WARNING: could not update $dest (continuing)"
  elif [ -d "$dest" ]; then
    echo "  WARNING: $dest exists but is not a git repo; skipping"
  else
    git clone "$@" "$url" "$dest"
  fi
}

# brew_formula <name>: install or upgrade a Homebrew formula.
brew_formula() {
  local name="$1"
  if brew list --formula "$name" &> /dev/null; then
    echo "  Upgrading $name via brew..."
    brew upgrade "$name"
  else
    echo "  Installing $name via brew..."
    brew install "$name"
  fi
}

# brew_cask <name>: install or upgrade a Homebrew cask.
brew_cask() {
  local name="$1"
  if brew list --cask "$name" &> /dev/null; then
    echo "  Upgrading $name via brew..."
    brew upgrade --cask "$name"
  else
    echo "  Installing $name via brew..."
    brew install --cask "$name"
  fi
}

# --- shell -------------------------------------------------------------------

echo "Installing oh my zsh..."
if [ -d "$HOME/.oh-my-zsh" ]; then
  # Deliberately not updated: OMZ ships its own periodic auto-updater.
  echo "oh-my-zsh already installed (auto-updates itself)"
else
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

echo "Configuring zsh..."
echo "Installing zshenv..."
link_dotfile "$PWD/.zshenv" "$HOME/.zshenv"
echo "Installing zshrc..."
link_dotfile "$PWD/.zshrc" "$HOME/.zshrc"

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

echo "Installing zsh-completions..."
clone_or_update https://github.com/zsh-users/zsh-completions "$ZSH_CUSTOM/plugins/zsh-completions"

echo "Installing zsh-syntax-highlighting..."
clone_or_update https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

echo "Installing zsh-autosuggestions..."
clone_or_update https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"

echo "Installing powerlevel10k..."
clone_or_update --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"

echo "Linking powerlevel10k config..."
link_dotfile "$PWD/.p10k.zsh" "$HOME/.p10k.zsh"

echo "Installing starship..."
if command -v brew &> /dev/null; then
  brew_formula starship
else
  echo "Installing/updating starship via curl..."
  curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

echo "Installing FiraCode Nerd Font..."
if command -v brew &> /dev/null; then
  brew_cask font-fira-code-nerd-font
else
  echo "brew not available, install FiraCode Nerd Font manually"
fi

echo "Linking starship config..."
mkdir -p "$HOME/.config"
link_dotfile "$PWD/starship.toml" "$HOME/.config/starship.toml"

echo "Linking Ghostty config..."
mkdir -p "$HOME/.config"
link_dotfile "$PWD/ghostty" "$HOME/.config/ghostty"

echo "Configuring gitconfig..."
DOTFILES_GITCONFIG="$PWD/.gitconfig"
LOCAL_GITCONFIG="$HOME/.gitconfig"

if [ -L "$LOCAL_GITCONFIG" ]; then
  BACKUP_PATH="$HOME/.gitconfig.symlink_backup.$(date +%Y%m%d%H%M%S)"
  echo "Backing up existing ~/.gitconfig symlink to $BACKUP_PATH"
  mv "$LOCAL_GITCONFIG" "$BACKUP_PATH"
  touch "$LOCAL_GITCONFIG"
elif [ ! -e "$LOCAL_GITCONFIG" ]; then
  touch "$LOCAL_GITCONFIG"
elif [ ! -f "$LOCAL_GITCONFIG" ]; then
  echo "ERROR: ~/.gitconfig exists but is not a regular file or symlink. Refusing to modify it."
  exit 1
fi

if git config --global --get-all include.path 2>/dev/null | grep -Fxq "$DOTFILES_GITCONFIG"; then
  echo "~/.gitconfig already includes dotfiles gitconfig"
else
  echo "Adding include for dotfiles gitconfig to ~/.gitconfig"
  git config --global --add include.path "$DOTFILES_GITCONFIG"
fi

# --- npm ---------------------------------------------------------------------

echo "Linking npm config..."
link_dotfile "$PWD/.npmrc" "$HOME/.npmrc"

echo "Installing tools..."

# load packages to install array from packages.yml into packages_to_install using mapfile
packages_to_install=($(awk -F"- " '{printf $2 "\n"}' packages.yml))
# For each package, install it if it's not installed, otherwise upgrade it
for package in "${packages_to_install[@]}"; do
  if command -v apt-get &> /dev/null; then
    echo "Installing/upgrading $package via apt-get..."
    sudo apt-get install -y "$package"
  else
    echo "Skipping $package: apt-get not available"
  fi
done

# Install or update uv for python package management
echo "Installing uv..."
if command -v brew &> /dev/null; then
  brew_formula uv
else
  echo "Installing/updating uv via curl..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

echo "Installing/updating thefuck via uv..."
# User-level on purpose: sudo would root-own the uv tool env (breaking later
# upgrades) and on Spin install into /root/.local, off PATH. --reinstall also
# self-heals a broken venv (e.g. a removed base python).
uv tool install --reinstall thefuck

echo "Installing spin specific tools..."
if [ -n "${SPIN:-}" ]; then
  echo "Ensure dirmngr daemon is started..."
  gpgconf --launch dirmngr
  echo "Configure gpg keys..."
  gpg --keyserver keys.openpgp.org --recv 1918338DA390B1AD0D3ECFB839146C2818B26AFE
fi

echo "Linking .vimrc ..."
link_dotfile "$PWD/.vimrc" "$HOME/.vimrc"

echo "Installing Nix package manager..."
if command -v nix &> /dev/null; then
  echo "Nix already installed"
elif [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
  echo "Nix already installed (multi-user); loading environment"
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
elif [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
  echo "Nix already installed (single-user); loading environment"
  . "$HOME/.nix-profile/etc/profile.d/nix.sh"
else
  echo "Nix not found, installing..."
  curl -L https://nixos.org/nix/install | sh
  . "$HOME/.nix-profile/etc/profile.d/nix.sh"
fi

echo "Configuring Nix to allow unfree packages..."
mkdir -p "$HOME/.config/nixpkgs"
echo "{ allowUnfree = true; }" > "$HOME/.config/nixpkgs/config.nix"

echo "Installing/updating tools via Nix..."
if command -v nix-env &> /dev/null; then
  nix-env -i -f ./tools.nix
  echo "Nix tools installed successfully"
else
  echo "Skipping Nix tools: nix-env not available"
fi

echo "Setting up Claude commands..."
mkdir -p "$HOME/.claude/commands"
cp -r claude/commands/* "$HOME/.claude/commands/"
echo "Claude commands copied successfully"
