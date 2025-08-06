# dotfiles

dotlou's default dotfiles - first thing to install on any new machine

## Features

### Shell Environment
- [powerline10k](https://github.com/romkatv/powerlevel10k) - Minimalist, dark, instant prompt
- [oh-my-zsh](https://github.com/ohmyzsh/ohmyzsh/) with plugins:
  - [zsh-completions](https://github.com/zsh-users/zsh-completions)
  - [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)
  - [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
- [thefuck](https://github.com/nvbn/thefuck) - Correct previous console commands

### Development Tools
- **Nix Package Manager** - Reproducible tool installation across all machines (see `tools.nix`)
- GPG signing public key + gitconfig to enforce signing of commits
- Vim configuration

### Claude Commands
- Custom Claude command configurations

![shell prompt](./images/powerline10k.png)

## Installation

```bash
git clone https://github.com/dotLou/dotfiles.git
cd dotfiles
./install.sh
```

This will:
1. Install Oh My Zsh and plugins
2. Configure Zsh with Powerlevel10k theme
3. Install Nix package manager (if not present)
4. Install development tools via Nix (defined in `tools.nix`)
5. Link configuration files (.zshrc, .gitconfig, .vimrc)
6. Set up Claude commands

## Customizing Tools

To add or remove tools, edit `tools.nix` and run:
```bash
nix-env -i -f ./tools.nix
```

To update all tools:
```bash
nix-env -u
```
