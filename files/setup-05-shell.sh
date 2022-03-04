#!/bin/bash
# Copyright 2019 VMware, Inc. All rights reserved.
# SPDX-License-Identifier: BSD-2

# Shell enhancements

set -euo pipefail

echo -e "\e[92mInstalling Shell Environment ..." > /dev/console

# Install ZSH
tdnf install -y zsh

# Unattended oh-my-zsh installation
sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Install Powerlin Fonts
git clone https://github.com/powerline/fonts.git --depth=1
cd fonts
./install.sh
cd ..
rm -rf fonts

# Install Powerlevel9k ZSH appearance
git clone https://github.com/bhilburn/powerlevel9k.git ~/.oh-my-zsh/custom/themes/powerlevel9k

# Add Powerlevel9k Theme as well as some appearance optimizations to .zshrc
sed -i '11i ZSH_THEME="powerlevel9k/powerlevel9k"' ~/.zshrc
sed -i '12i POWERLEVEL9K_SHORTEN_DIR_LENGTH=3' ~/.zshrc
sed -i '13i POWERLEVEL9K_SHORTEN_DELIMITER=””' ~/.zshrc
sed -i '14i POWERLEVEL9K_PROMPT_ON_NEWLINE=true' ~/.zshrc
sed -i '15i POWERLEVEL9K_SHORTEN_STRATEGY=truncate_from_right' ~/.zshrc
sed -i '16i POWERLEVEL9K_TIME_BACKGROUND=blue' ~/.zshrc
sed -i '17i POWERLEVEL9K_DATE_BACKGROUND=cyan' ~/.zshrc
sed -i '18i POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(kubecontext time date)' ~/.zshrc
sed -i '19i POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(user dir vcs)' ~/.zshrc

# Delete old Theme in .zshrc
sed -i "20d" ~/.zshrc

# Setting aliases in .zshrc
sed -i -e '$aalias k=kubectl' ~/.zshrc
sed -i -e '$aalias c=clear' ~/.zshrc
sed -i -e '$aalias w="watch -n1"' ~/.zshrc

# Add Syntax Highlighting to ZSH
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
sed -i "81d" ~/.zshrc
sed -i '83i plugins=(git zsh-syntax-highlighting)' ~/.zshrc

# ZSH Autocompletion for kubectl
sed -i -e '$aif [ /usr/bin/kubectl ]; then source <(kubectl completion zsh); fi' ~/.zshrc

# Install Helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
rm get_helm.sh

# Changing the default shell from bash to zsh
chsh -s $(which zsh)
