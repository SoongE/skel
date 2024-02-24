CONTAINER_NAME=$1
HOST_NAME=$2
PORT=$3
IMAGE_NAME=$4

my_uid=$(/usr/bin/id -u)
shared_gid=$(getent group shared | cut -d: -f3)

M_DIR=dmount
PRIVATE=/home/$USER/$M_DIR
SHARED=/var/shared

mkdir $PRIVATE
cp /home/$USER/.ssh/authorized_keys $PRIVATE/authorized_keys

docker run --gpus all --ipc=host --shm-size=10g --ulimit memlock=-1 --ulimit stack=67108864 --privileged --hostname $HOST_NAME --name $CONTAINER_NAME --restart unless-stopped -p $PORT:33 -v $PRIVATE:$PRIVATE -v $SHARED:/home/$USER/shared -itd $IMAGE_NAME /bin/zsh

echo 'Add shared group'
docker exec -it $CONTAINER_NAME adduser -uid $my_uid $USER
docker exec -it $CONTAINER_NAME groupadd --gid $shared_gid shared

echo 'Set sudo user permission and shared foler access'
docker exec -it $CONTAINER_NAME usermod -aG sudo $USER
docker exec -it $CONTAINER_NAME usermod -aG shared $USER

echo 'Make .ssh foler and give user permission'
docker exec -it $CONTAINER_NAME mkdir /home/$USER/.ssh && chown -R $USER:$USER /home/$USER/.ssh

echo 'Copy user public key from server to container'
docker exec -it $CONTAINER_NAME cp /home/$USER/$M_DIR/authorized_keys /home/$USER/.ssh/authorized_keys

echo 'Change .ssh folder and public key permission'
docker exec -it $CONTAINER_NAME chmod 700 /home/$USER/.ssh && chmod 600 /home/$USER/.ssh/authorized_keys

echo 'Copy skel'
docker exec -it $CONTAINER_NAME bash -c "cp -r /etc/skel /home/$USER"

echo 'Modify owner of skel'
docker exec -it $CONTAINER_NAME bash -c "chown -R $USER:$USER /home/$USER/skel"

echo 'Move skel'
docker exec -it $CONTAINER_NAME bash -c "mv /home/$USER/skel/.* /home/$USER; rm -rf /home/$USER/skel"

echo 'Make zsh default'
docker exec -it $CONTAINER_NAME bash -c "usermod -s /bin/zsh $USER"

echo 'Change owner to $USER'
docker exec -it $CONTAINER_NAME chown $USER:$USER /home/$USER/
docker exec -it $CONTAINER_NAME chown -R $USER:$USER /home/$USER/.ssh
docker exec -it $CONTAINER_NAME chown -R $USER:$USER /home/$USER/$M_DIR

echo 'make fd-find and bat aliases'
mkdir ~/.local/bin
ln -s $(which fdfind) ~/.local/bin/fd
ln -s $(which batcat) ~/.local/bin/bat
