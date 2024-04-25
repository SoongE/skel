apt-get -y update; apt-get -y upgrade;

apt-get -y install ssh sshfs openssh-server sudo git tree zsh tmux zip rsync systemd vim wget curl tzdata autojump language-pack-en miller fd-find bat iotop iftop imagemagick ranger progress net-tools lsof libgl1-mesa-glx libglib2.0-0
# apt-get -y install build-essential ffmpeg libsm6 libxext6 libudev-dev libncurses* texlive-full

apt-get clean autoclean; apt-get -y autoremove --purge

pip install --upgrade transformers timm wandb einops tmuxp nvitop lightning torchmetrics ujson hydra-core captum seaborn deepspeed datasets wilds accelerate open_clip_torch img2dataset 

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
cp skel/HelveticaFont/* /usr/local/lib/python3.10/dist-packages/matplotlib/mpl-data/fonts/ttf
rm -r skel
omz reload

# make fd-find and bat aliases
ln -s $(which fdfind) ~/.local/bin/fd
ln -s $(which batcat) ~/.local/bin/bat

echo Todo
echo '1. Modify sshd_config\n 2. Make "/data" folder'
