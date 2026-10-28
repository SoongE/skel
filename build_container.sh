#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 4 ]]; then
  echo "Usage: $0 <container_name> <host_name> <port> <image_name>" >&2
  exit 1
fi

CONTAINER=$1
CONTAINER_HOSTNAME=$2
PORT=$3
IMAGE=$4

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_NAME="$(id -un)"
USER_ID="$(id -u)"
GROUP_NAME="$(id -gn)"
GROUP_ID="$(id -g)"
SHARED_GID="$(getent group shared | cut -d: -f3 || true)"
CONTAINER_HOME="/home/$USER_NAME"
PRIVATE="$HOME/dmount"
SHARED=/var/shared

if [[ -z ${CONTAINER_PASSWORD:-} ]]; then
  read -rsp "Password for $USER_NAME in container: " CONTAINER_PASSWORD
  echo
fi

mkdir -p "$PRIVATE" "$HOME/.cache"

volumes=(
  -v "$PRIVATE:$PRIVATE"
  -v "$HOME/.cache:$CONTAINER_HOME/.cache"
  -v "$HOME/.ssh:$CONTAINER_HOME/.ssh"
  -v /tmp:/tmp
)
if [[ -n $SHARED_GID ]]; then
  volumes+=(-v "$SHARED:$CONTAINER_HOME/shared")
fi

echo "====> Launching container '$CONTAINER'"
docker run --gpus all \
  --ipc=host --pid=host \
  --shm-size=10g \
  --ulimit memlock=-1 --ulimit stack=67108864 \
  --hostname "$CONTAINER_HOSTNAME" --name "$CONTAINER" \
  -p "$PORT":33 \
  "${volumes[@]}" \
  -e TZ=Asia/Seoul \
  -e NVIDIA_DRIVER_CAPABILITIES=compute,utility,graphics \
  -itd "$IMAGE" /bin/bash -c "service ssh start; sleep infinity"

trap 'docker exec "$CONTAINER" rm -f "/etc/sudoers.d/$USER_NAME" >/dev/null 2>&1 || true' EXIT

echo "====> Root setup: base packages, user, sshd"
docker exec \
  -e USER_NAME="$USER_NAME" -e USER_ID="$USER_ID" \
  -e GROUP_NAME="$GROUP_NAME" -e GROUP_ID="$GROUP_ID" \
  -e SHARED_GID="$SHARED_GID" -e CONTAINER_PASSWORD="$CONTAINER_PASSWORD" \
  "$CONTAINER" bash -euo pipefail -c '
export DEBIAN_FRONTEND=noninteractive
ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime
echo Asia/Seoul > /etc/timezone

apt-get update
apt-get install -y --no-install-recommends sudo zsh git curl ca-certificates openssh-server

existing_user="$(getent passwd "$USER_ID" | cut -d: -f1 || true)"
if [[ -n $existing_user && $existing_user != "$USER_NAME" ]]; then
  userdel "$existing_user"
fi
existing_group="$(getent group "$GROUP_ID" | cut -d: -f1 || true)"
if [[ -z $existing_group ]]; then
  groupadd -g "$GROUP_ID" "$GROUP_NAME"
elif [[ $existing_group != "$GROUP_NAME" ]]; then
  groupmod -n "$GROUP_NAME" "$existing_group"
fi
id -u "$USER_NAME" >/dev/null 2>&1 || useradd -M -d "/home/$USER_NAME" -u "$USER_ID" -g "$GROUP_ID" -s /bin/zsh "$USER_NAME"
usermod -aG sudo "$USER_NAME"
if [[ -n $SHARED_GID ]]; then
  getent group shared >/dev/null || groupadd -g "$SHARED_GID" shared
  usermod -aG shared "$USER_NAME"
fi
echo "$USER_NAME:$CONTAINER_PASSWORD" | chpasswd

echo "$USER_NAME ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$USER_NAME"
chmod 440 "/etc/sudoers.d/$USER_NAME"

mkdir -p "/home/$USER_NAME"
chown "$USER_NAME:$GROUP_NAME" "/home/$USER_NAME"

mkdir -p /etc/ssh/sshd_config.d
grep -q "^Include /etc/ssh/sshd_config.d/" /etc/ssh/sshd_config \
  || sed -i "1i Include /etc/ssh/sshd_config.d/*.conf" /etc/ssh/sshd_config
cat > /etc/ssh/sshd_config.d/00-custom.conf <<EOF
Port 33
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitEmptyPasswords no
PermitRootLogin no
UsePAM yes
EOF
service ssh restart
'

echo "====> Copying dotfiles"
docker cp "$DOTFILES" "$CONTAINER:$CONTAINER_HOME/.dotfiles"
docker exec "$CONTAINER" chown -R "$USER_NAME:$GROUP_NAME" "$CONTAINER_HOME/.dotfiles"

echo "====> User setup"
docker exec -u "$USER_NAME" -w "$CONTAINER_HOME" -e HOME="$CONTAINER_HOME" -e USER="$USER_NAME" \
  "$CONTAINER" "$CONTAINER_HOME/.dotfiles/install.sh"
docker exec "$CONTAINER" rm -rf "$CONTAINER_HOME/.dotfiles"

echo "Done! Container '$CONTAINER' is ready on port $PORT."
