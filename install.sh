#!/bin/bash

echo "Installing oh my zsh..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo "Configuring zsh..."
mv $HOME/.zshrc $HOME/.zshrc_backup
ln -s $PWD/.zshrc $HOME/.zshrc
git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

echo "Installing powerlevel10k..."
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

echo "Linking powerlevel10k config..."
ln -s $PWD/.p10k.zsh $HOME/.p10k.zsh

echo "Linking gitconfig..."
rm -rf $HOME/.gitconfig
ln -s $PWD/.gitconfig $HOME/.gitconfig

echo "Installing tools..."

# load packages to install array from packages.yml into packages_to_install using mapfile
packages_to_install=($(awk -F"- " '{printf $2 "\n"}' packages.yml))
# For each package, install it if it's not installed
for package in "${packages_to_install[@]}"; do
  if ! command -v $package &> /dev/null; then
    echo "Installing $package via apt-get..."
    sudo apt-get install -y $package
  else
    echo "Package $package already installed"
  fi
done

if ! command -v thefuck &> /dev/null; then
  echo "Installing thefuck via pip3..."
  sudo pip3 install thefuck
fi

echo "Installing spin specific tools..."
if [ $SPIN ]; then
  echo "Configure gpg keys..."
  gpg --keyserver keys.openpgp.org --recv 1918338DA390B1AD0D3ECFB839146C2818B26AFE
fi
