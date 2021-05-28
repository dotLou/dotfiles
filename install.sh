#!/bin/sh

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
if ! command -v thefuck &> /dev/null; then
  sudo apt-get install -y python3-dev python3-pip python3-setuptools
  sudo pip3 install thefuck
fi

echo "Installing spin specific tools..."
if [ $SPIN ]; then
  echo "Configure gpg keys..."
  gpgconf --launch dirmngr
  gpg --keyserver keys.openpgp.org --recv 1918338DA390B1AD0D3ECFB839146C2818B26AFE
fi
