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

my_uid=$(/usr/bin/id -u)
shared_gid=$(getent group shared | cut -d: -f3)

M_DIR=dmount
PRIVATE=/home/$USER/$M_DIR
SHARED=/var/shared

mkdir -p $PRIVATE

docker run --gpus all \
  --ipc=host \
  --pid=host \
  --shm-size=10g \
  --ulimit memlock=-1 --ulimit stack=67108864 \
  --hostname $HOST_NAME --name $CONTAINER_NAME \
  -p $PORT:33 \
  -v $PRIVATE:$PRIVATE \
  -v $SHARED:/home/$USER/shared \
  -v /home/$USER/.cache:/home/$USER/.cache \
  -v /home/$USER/.ssh:/home/$USER/.ssh:ro \
  -v /etc/localtime:/etc/localtime:ro \
  -v /tmp:/tmp \
  -e TZ=Asia/Seoul \
  -itd $IMAGE_NAME /bin/zsh

dexec() {
    docker exec $CONTAINER_NAME bash -c "$1"
}

echo 'Add user and shared group'
dexec "adduser -uid $my_uid $USER"
dexec "groupadd --gid $shared_gid shared"

echo 'Set user password'
dexec "echo '$USER:$PASSWORD' | chpasswd"

echo 'Set sudo and shared folder permission'
dexec "usermod -aG sudo $USER && usermod -aG shared $USER"

echo 'Copy skel and set zsh as default'
dexec "cp -r /etc/skel /home/$USER/skel \
       && chown -R $USER:$USER /home/$USER/skel \
       && mv /home/$USER/skel/.* /home/$USER/ 2>/dev/null || true \
       && rm -rf /home/$USER/skel \
       && usermod -s /bin/zsh $USER"

echo 'Final ownership fix'
dexec "chown $USER:$USER /home/$USER/ \
       && chown -R $USER:$USER /home/$USER/$M_DIR"

echo 'Make fd-find and bat aliases inside container'
dexec "mkdir -p /home/$USER/.local/bin \
       && command -v fdfind >/dev/null && ln -sf \$(which fdfind) /home/$USER/.local/bin/fd || true \
       && command -v batcat >/dev/null && ln -sf \$(which batcat) /home/$USER/.local/bin/bat || true \
       && chown -R $USER:$USER /home/$USER/.local"

echo "Done! Container '$CONTAINER_NAME' is ready on port $PORT."