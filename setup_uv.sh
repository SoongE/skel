apt-get -y update; apt-get -y upgrade;

apt-get -y install sudo ssh sshfs openssh-server sudo git tree zsh tmux zip rsync systemd vim wget curl tzdata autojump language-pack-en miller fd-find bat iotop iftop progress net-tools lsof libglib2.0-0 libaio-dev libnccl2 libnccl-dev
# apt-get -y install build-essential ffmpeg libsm6 libxext6 libudev-dev libncurses* texlive-full

apt-get clean autoclean; apt-get -y autoremove --purge

# UV install
curl -LsSf https://astral.sh/uv/install.sh | sh
uv pip install --system --break-system-packages nvitop tmuxp --torch-backend=auto

# Setup default venv and install default torch depend on system cuda version
uv venv .base_venv --prompt base
uv pip install --python .base_venv/bin/python numpy torch --torch-backend=auto

# Setup zsh
sh -c "$(wget https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"
chsh -s $(which zsh) $USER
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# paste skel files
cd ~
git clone https://github.com/SoongE/skel.git
rm -rf .profile .bashrc .bash_history .zshrc .zprofile .zcompdump*
cp -r skel/skel/.* .
rm -r /etc/skel
cp -r skel/skel /etc
cp -r .oh-my-zsh /etc/skel
mv skel/helvetica-neue /usr/share/fonts/truetype
rm -r skel
zstyle ':omz:update' mode auto
zstyle ':omz:update' verbose minimal

# make fd-find and bat aliases
mkdir -p ~/.local/bin
ln -s $(which fdfind) ~/.local/bin/fd
ln -s $(which batcat) ~/.local/bin/cat

omz reload

echo "Setup complete!"