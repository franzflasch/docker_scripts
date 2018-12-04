#!/bin/bash

set -e

print_usage() {
   echo "usage: $0 <docker_image> <username> <host_shared_dir> <docker_shared_dir> <optional_docker_args>"
   echo "example call:"
   echo "./docker_start_with_x.sh -i ubuntu18_04_3dprinting:1 -u franz -o \"-v /home/franz/:/working_dir --device /dev/ttyUSB0\""
   echo "use this as optional_docker_arf to enable support for tun/tap devices in docker:"
   echo "--cap-add=NET_ADMIN --device /dev/net/tun"
   echo ""
   echo "Options:"
   echo "-u       username within docker image"
   echo "-i       docker image to take"
   echo "-o       optional docker arguments e.g. \"-v<some-dir>:<some-dir>\""
   echo "-r       auto remove docker container after exit"
   echo "--ssh    map SSH agent socket into container, so that host ssh-keys can be used within docker container"
   exit 1
}

# Parse commandline parameters
POSITIONAL=()
while [[ $# -gt 0 ]]
do
  key="$1"

  case $key in
      -i|--image)
      DOCKER_IMAGE="$2"
      shift # past argument
      shift # past value
      ;;
      -u|--user)
      DOCKER_USER="$2"
      shift # past argument
      shift # past value
      ;;
      -o|--optargs)
      OPT_DOCKER_ARGS="$2"
      shift # past argument
      shift # past value
      ;;
      -r|--rm)
      REMOVE_FLAG="--rm"
      shift # past argument
      ;;
      --ssh)
      ssh_auth_sock_file=$(dirname $SSH_AUTH_SOCK)/$(basename $SSH_AUTH_SOCK)
      DOCKER_SSH_AUTH_SOCK_OPTS="-v $ssh_auth_sock_file:$ssh_auth_sock_file -e SSH_AUTH_SOCK=$SSH_AUTH_SOCK"
      shift # past argument
      ;;
      -h|--help)
      print_usage
      ;;
      *)    # unknown option
      POSITIONAL+=("$1") # save it in an array for later
      shift # past argument
      ;;
  esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

if [ -z ${DOCKER_IMAGE+x} ]; then print_usage; fi

echo "Starting image $DOCKER_IMAGE with the following options:"
echo DOCKER_USER      = "${DOCKER_USER}"
echo OPT_DOCKER_ARGS  = "${OPT_DOCKER_ARGS}"
echo REMOVE_FLAG      = "${REMOVE_FLAG}"
echo DOCKER_SSH_AUTH_SOCK_OPTS = "${DOCKER_SSH_AUTH_SOCK_OPTS}"

## Graphical SECTION
# -e DISPLAY=$DISPLAY \
# -v /tmp/.X11-unix:/tmp/.X11-unix \
# --device /dev/dri \

## Sound support
# --group-add $(getent group audio | cut -d: -f3) \
# --device /dev/snd \
# -v /run/user/$(id -u)/pulse:/run/user/$(id -u)/pulse \

## This is needed by some applications e.g. gnome-terminal:
# -v /run/dbus/:/run/dbus/ \
# -v /dev/shm:/dev/shm \

docker run -ti $REMOVE_FLAG\
           --user=$DOCKER_USER \
           -e DISPLAY=$DISPLAY \
           -v /tmp/.X11-unix:/tmp/.X11-unix \
           --device /dev/dri \
           --group-add $(getent group audio | cut -d: -f3) \
           --device /dev/snd \
           -v /run/user/$(id -u)/pulse:/run/user/$(id -u)/pulse \
           -v /run/dbus/:/run/dbus/ \
           -v /dev/shm:/dev/shm \
           $DOCKER_SSH_AUTH_SOCK_OPTS \
           $OPT_DOCKER_ARGS \
           $DOCKER_IMAGE
