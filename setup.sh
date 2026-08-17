apt-get -y update; apt-get -y upgrade;

apt-get -y install sudo ssh sshfs openssh-server sudo git tree zsh tmux zip rsync systemd vim wget curl tzdata autojump language-pack-en miller fd-find bat iotop iftop imagemagick ranger progress net-tools lsof libglib2.0-0 libaio-dev zsh
# apt-get -y install build-essential ffmpeg libsm6 libxext6 libudev-dev libncurses* texlive-full

apt-get clean autoclean; apt-get -y autoremove --purge

pip install --root-user-action=ignore --upgrade transformers timm wandb einops tmuxp nvitop torchmetrics ujson seaborn deepspeed datasets accelerate img2dataset jupyterlab

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
cp skel/HelveticaFont/* /usr/local/lib/python3.10/dist-packages/matplotlib/mpl-data/fonts/ttf
rm -r skel

# make fd-find and bat aliases
mkdir -p ~/.local/bin
ln -s $(which fdfind) ~/.local/bin/fd
ln -s $(which batcat) ~/.local/bin/bat

source ~/.zshrc

echo Todo
echo '1. Modify sshd_config\n 2. Make "/data" folder'
