#!/bin/bash
set -euo pipefail

if [ $# -lt 4 ]; then
    echo "Usage: $0 <container_name> <host_name> <port> <image_name>"
    exit 1
fi

CONTAINER_NAME=$1
HOST_NAME=$2
PORT=$3
IMAGE_NAME=$4
PASSWORD=1234

MY_UID=$(/usr/bin/id -u)
SHARED_GID=$(getent group shared | cut -d: -f3)

M_DIR=dmount
PRIVATE=/home/$USER/$M_DIR
SHARED=/var/shared

mkdir -p "$PRIVATE"

# ---------- 1. Launch container ----------
echo "====> Launching container '$CONTAINER_NAME'"
docker run --gpus all \
  --ipc=host --pid=host \
  --shm-size=10g \
  --ulimit memlock=-1 --ulimit stack=67108864 \
  --hostname "$HOST_NAME" --name "$CONTAINER_NAME" \
  -p "$PORT":33 \
  -v "$PRIVATE":"$PRIVATE" \
  -v "$SHARED":/home/$USER/shared \
  -v /home/$USER/.cache:/home/$USER/.cache \
  -v /home/$USER/.ssh:/home/$USER/.ssh:ro \
  -v /tmp:/tmp \
  -e TZ=Asia/Seoul \
  -itd "$IMAGE_NAME" /bin/bash -c "service ssh start; sleep infinity"

# ---------- 2. Root setup (single exec) ----------
echo "====> Root setup: apt, user, sudo"
docker exec "$CONTAINER_NAME" bash -euo pipefail -c "
export DEBIAN_FRONTEND=noninteractive

# Pre-configure timezone
ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime
echo 'Asia/Seoul' > /etc/timezone

apt-get update
apt-get -y install --no-install-recommends \
  sudo ssh sshfs openssh-server git tree zsh tmux zip rsync systemd vim \
  wget curl ca-certificates tzdata autojump language-pack-en miller \
  fd-find bat iotop iftop progress net-tools lsof \
  libglib2.0-0 libaio-dev libnccl2 libnccl-dev
apt-get clean
rm -rf /var/lib/apt/lists/*

useradd -m -u $MY_UID -s /bin/zsh $USER
groupadd --gid $SHARED_GID shared
usermod -aG sudo,shared $USER
echo '$USER:$PASSWORD' | chpasswd

# Passwordless sudo for the rest of setup
echo '$USER ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/$USER
chmod 440 /etc/sudoers.d/$USER

chown $USER:$USER /home/$USER
chown -R $USER:$USER /home/$USER/$M_DIR

# Make sshd listen on port 33 (matches '-p \$PORT:33')
echo 'Port 33' > /etc/ssh/sshd_config.d/port.conf

service ssh restart
"

# ---------- 3. User setup (single exec as $USER) ----------
echo "====> User setup: uv, venv, oh-my-zsh, dotfiles"
docker exec -u "$USER" -w "/home/$USER" -e HOME="/home/$USER" "$CONTAINER_NAME" bash -euo pipefail -c '
# UV + system tools
curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="$HOME/.local/bin:$PATH"
sudo env "PATH=$PATH" uv pip install --system --break-system-packages nvitop tmuxp --torch-backend=auto

# Base venv with torch
cd ~
uv venv .base_venv --prompt base
uv pip install --python .base_venv/bin/python torch numpy transformers timm wandb einops datasets accelerate jupyterlab --torch-backend=auto

# Oh-my-zsh (unattended) + syntax-highlighting
RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git \
  ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Dotfiles from SoongE/skel
git clone --depth=1 https://github.com/SoongE/skel.git
rm -rf .profile .bashrc .bash_history .zshrc .zprofile .zcompdump*
cp -rT skel/skel .
sudo rm -rf /etc/skel
sudo cp -r skel/skel /etc/skel
sudo cp -r .oh-my-zsh /etc/skel
sudo mkdir -p /usr/share/fonts/truetype/
sudo mv skel/helvetica-neue /usr/share/fonts/truetype/
rm -rf skel

# fd / bat shims
mkdir -p ~/.local/bin
ln -sf "$(command -v fdfind)" ~/.local/bin/fd
ln -sf "$(command -v batcat)" ~/.local/bin/bat
'

# ---------- 4. Restore password-required sudo ----------
echo "====> Restoring password-required sudo"
docker exec "$CONTAINER_NAME" rm -f "/etc/sudoers.d/$USER"

echo "Done! Container '$CONTAINER_NAME' is ready on port $PORT."