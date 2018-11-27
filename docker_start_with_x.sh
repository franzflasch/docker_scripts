#!/bin/bash

set -e

if [ $# -lt 4 ]; then
   echo "usage: $0 <docker_image> <username> <host_shared_dir> <docker_shared_dir> <optional_docker_args>"
   echo "example call:"
   echo "./docker_start_with_x.sh ubuntu18_04_3dprinting:1 franz /home/franz/ /working_dir \"--device /dev/ttyUSB0\""
   echo "use this as optional_docker_arf to enable support for tun/tap devices in docker:"
   echo "--cap-add=NET_ADMIN --device /dev/net/tun"
   exit 1
fi

DOCKER_IMAGE=$1
DOCKER_USER=$2
HOST_SHARED_DIR=$3
DOCKER_SHARED_DIR=$4
OPT_DOCKER_ARGS=$5

docker run -ti --rm \
           --user=$DOCKER_USER \
           -e DISPLAY=$DISPLAY \
           -v /tmp/.X11-unix:/tmp/.X11-unix \
           --group-add $(getent group audio | cut -d: -f3) \
           --device /dev/snd \
           --device /dev/dri \
           -v /run/user/$(id -u)/pulse:/run/user/$(id -u)/pulse \
           -v /run/dbus/:/run/dbus/ \
           -v /dev/shm:/dev/shm \
           -v $HOST_SHARED_DIR:$DOCKER_SHARED_DIR \
           $OPT_DOCKER_ARGS \
           $DOCKER_IMAGE
