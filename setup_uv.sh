apt-get -y update; apt-get -y upgrade;

apt-get -y install sudo ssh sshfs openssh-server sudo git tree zsh tmux zip rsync systemd vim wget curl tzdata autojump language-pack-en miller fd-find bat iotop iftop progress net-tools lsof libglib2.0-0 libaio-dev libnccl2 libnccl-dev ncurses-term
# apt-get -y install build-essential ffmpeg libsm6 libxext6 libudev-dev libncurses* texlive-full

apt-get clean autoclean; apt-get -y autoremove --purge

# UV install
curl -LsSf https://astral.sh/uv/install.sh | sh
uv pip install --system --break-system-packages hf_transfer nvitop tmuxp --torch-backend=auto

# Setup default venv and install default torch depend on system cuda version
uv venv .base_venv --prompt base
uv pip install --python .base_venv/bin/python hf_transfer numpy torch ipykernel --torch-backend=auto

# Setup zsh
curl -sS https://starship.rs/install.sh | sh -s -- -y -b ~/.local/bin
bash -c "$(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
chsh -s $(which zsh)

# paste skel files
cd ~
git clone https://github.com/SoongE/skel.git
rm -rf .profile .bashrc .bash_history .zshrc .zprofile .zcompdump*
cp -r skel/skel/.* .
rm -r /etc/skel
cp -r skel/skel /etc
mv skel/helvetica-neue /usr/share/fonts/truetype
rm -r skel

# make fd-find and bat aliases
mkdir -p ~/.local/bin
ln -s $(which fdfind) ~/.local/bin/fd
ln -s $(which batcat) ~/.local/bin/cat

source ~/.zshrc

echo "Setup complete!"
